//
//  AuthManager.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import Foundation
import SwiftUI
import Supabase
import GoogleSignIn
import Combine
import AuthenticationServices

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noPresentingViewController
    case noIdToken
    
    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "Unable to present Google Sign-In"
        case .noIdToken:
            return "No ID token received from Google"
        }
    }
}

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: Supabase.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userFirstName: String?
    
    var appleSignInCoordinator: AppleSignInCoordinator?
    
    let supabase: SupabaseClient
    
    init() {
        // Initialize Supabase client
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
        
        // Load saved first name
        self.userFirstName = UserDefaults.standard.string(forKey: "userFirstName")
        print("🔄 AuthManager init - loaded first name: \(self.userFirstName ?? "nil")")
        
        // Set initial loading state
        self.isLoading = true
        
        // Check if user is already authenticated
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Status
    @MainActor
    func checkAuthStatus() async {
        let startTime = Date()
        
        do {
            let session = try await supabase.auth.session
            self.user = session.user
            self.isAuthenticated = session.user != nil
            
            // If authenticated, ensure profile exists
            if self.isAuthenticated {
                await ensureProfileExists()
            }
        } catch {
            // sessionMissing is normal when user is not logged in
            if error.localizedDescription.contains("sessionMissing") {
                self.isAuthenticated = false
                self.user = nil
                print("No active session - user not logged in")
            } else {
                print("Error checking auth status: \(error)")
                self.isAuthenticated = false
                self.user = nil
            }
        }
        
        // Ensure minimum 0.5 second loading time
        let elapsed = Date().timeIntervalSince(startTime)
        let remainingTime = max(0, 0.5 - elapsed)
        
        if remainingTime > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
        
        isLoading = false
    }
    
    // MARK: - Profile Management
    @MainActor
    func ensureProfileExists() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            let email = session.user.email ?? ""
            
            // Check if profile already exists
            let existing: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if existing.isEmpty {
                print("📝 Creating profile for new user: \(userId)")
                
                // Generate username from email
                let username = email.components(separatedBy: "@").first ?? "user_\(UUID().uuidString.prefix(8))"
                
                // Create the profile
                struct ProfileInsert: Encodable {
                    let id: UUID
                    let username: String
                    let display_name: String
                }
                
                let displayName = userFirstName ?? username
                let profile = ProfileInsert(
                    id: userId,
                    username: username,
                    display_name: displayName
                )
                
                try await supabase
                    .from("profiles")
                    .insert(profile)
                    .execute()
                
                // Create initial user progress
                struct ProgressInsert: Encodable {
                    let user_id: UUID
                    let current_streak: Int
                    let longest_streak: Int
                    let total_xp: Int
                    let current_level: Int
                }
                
                let progress = ProgressInsert(
                    user_id: userId,
                    current_streak: 0,
                    longest_streak: 0,
                    total_xp: 0,
                    current_level: 1
                )
                
                try await supabase
                    .from("user_progress")
                    .insert(progress)
                    .execute()
                
                print("✅ Profile and progress created successfully")
            } else {
                print("✅ Profile already exists")
            }
        } catch {
            print("⚠️ Error ensuring profile exists: \(error)")
            // Don't throw - app should work without profile
        }
    }
    
    // MARK: - Google Sign-In
    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Configure Google Sign-In
            guard let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = scene.windows.first?.rootViewController else {
                throw AuthError.noPresentingViewController
            }
            
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
            
            // Perform Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.noIdToken
            }
            
            // Extract first name from Google profile
            let firstName = user.profile?.givenName
            
            // Sign in to Supabase with Google token
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )
            
            self.user = session.user
            self.isAuthenticated = session.user != nil
            
            print("🔐 Google Sign-In successful!")
            print("   User: \(session.user.id)")
            print("   isAuthenticated: \(self.isAuthenticated)")
            print("   Current thread: \(Thread.isMainThread ? "Main" : "Background")")
            
            // Save first name if available
            if let firstName = firstName {
                self.userFirstName = firstName
                UserDefaults.standard.set(firstName, forKey: "userFirstName")
                print("✅ Saved user first name: \(firstName)")
            } else {
                print("⚠️ No first name available from Google")
            }
            
            // Ensure profile exists in database
            await ensureProfileExists()
            
        } catch {
            print("❌ Google Sign-In error: \(error)")
            print("   Error description: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("📊 Final state - isLoading: \(isLoading), isAuthenticated: \(isAuthenticated)")
    }
    
    // MARK: - Apple Sign-In
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        // Create and set the coordinator as delegate
        let coordinator = AppleSignInCoordinator(authManager: self)
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        
        // Store coordinator to prevent deallocation
        self.appleSignInCoordinator = coordinator
        
        authorizationController.performRequests()
    }
    
    // MARK: - Sign Out
    @MainActor
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.signOut()
            self.isAuthenticated = false
            self.user = nil
            self.userFirstName = nil
            // Clear saved data
            UserDefaults.standard.removeObject(forKey: "userFirstName")
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "onboardingGratitude")
        } catch {
            print("Sign out error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
}

// MARK: - Apple Sign-In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    weak var authManager: AuthManager?
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let authManager = authManager else { return }
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let identityTokenData = appleIDCredential.identityToken,
           let identityToken = String(data: identityTokenData, encoding: .utf8) {
            
            let firstName = appleIDCredential.fullName?.givenName
            
            // Complete sign in on main actor
            Task { @MainActor in
                do {
                    // Sign in to Supabase with Apple token
                    let session = try await authManager.supabase.auth.signInWithIdToken(
                        credentials: .init(
                            provider: .apple,
                            idToken: identityToken
                        )
                    )
                    
                    authManager.user = session.user
                    authManager.isAuthenticated = session.user != nil
                    
                    // Save first name if available
                    if let firstName = firstName {
                        authManager.userFirstName = firstName
                        UserDefaults.standard.set(firstName, forKey: "userFirstName")
                        print("✅ Saved user first name: \(firstName)")
                    }
                    
                    // Ensure profile exists in database
                    await authManager.ensureProfileExists()
                    
                    authManager.isLoading = false
                    
                } catch {
                    print("Apple Sign-In error: \(error)")
                    authManager.errorMessage = error.localizedDescription
                    authManager.isLoading = false
                }
            }
        } else {
            Task { @MainActor in
                authManager.errorMessage = "No ID token received from Apple"
                authManager.isLoading = false
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let authManager = authManager else { return }
        
        Task { @MainActor in
            // Check if user cancelled
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue {
                print("Apple Sign-In cancelled by user")
            } else {
                print("Apple Sign-In error: \(error)")
                authManager.errorMessage = error.localizedDescription
            }
            authManager.isLoading = false
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("Unable to get window for Apple Sign-In presentation")
        }
        return window
    }
}
