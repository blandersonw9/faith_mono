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
    
    let supabase: SupabaseClient
    
    init() {
        // Initialize Supabase client
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
        
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
    
    // MARK: - Google Sign-In
    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Configure Google Sign-In
            guard let presentingViewController = await UIApplication.shared.windows.first?.rootViewController else {
                throw AuthError.noPresentingViewController
            }
            
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
            
            // Perform Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.noIdToken
            }
            
            // Sign in to Supabase with Google token
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )
            
            self.user = session.user
            self.isAuthenticated = session.user != nil
            
        } catch {
            print("Google Sign-In error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign-In (Ready for future implementation)
    @MainActor
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Apple Sign-In when ready
        // This is a placeholder for future Apple Sign-In implementation
        self.errorMessage = "Apple Sign-In not yet configured"
        isLoading = false
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
        } catch {
            print("Sign out error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
}
