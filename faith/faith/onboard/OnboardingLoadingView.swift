//
//  OnboardingLoadingView.swift
//  faith
//
//  Created on 10/1/25.
//

import SwiftUI
import Supabase
import Combine

struct OnboardingLoadingView: View {
    @EnvironmentObject var authManager: AuthManager
    let onComplete: () -> Void
    
    @State private var responseText: String = ""
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            StyleGuide.backgroundBeige
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 80)
                
                // Glowing Halo at full brightness with pulsing animation
                GlowingHalo(progress: 1.0)
                    .scaleEffect(isLoading ? pulseScale : 1.0)
                    .opacity(isLoading ? 0.85 + (pulseScale - 0.95) * 0.3 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: isLoading)
                    .padding(.bottom, StyleGuide.spacing.xxl)
                
                // Response text
                ScrollView {
                    VStack(spacing: StyleGuide.spacing.lg) {
                        if !responseText.isEmpty {
                            AnimatedTypingText(
                                fullText: responseText,
                                font: StyleGuide.merriweather(size: 20, weight: .regular),
                                color: StyleGuide.mainBrown,
                                lineSpacing: 8
                            )
                        }
                    }
                    .padding(.horizontal, StyleGuide.spacing.xl)
                }
                
                Spacer()
                
                // Continue button (appears after text finishes typing)
                if !isLoading && !responseText.isEmpty {
                    Button(action: {
                        Task {
                            await saveOnboardingDataToSupabase()
                            // Add delay and animation for smooth transition
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    onComplete()
                                }
                            }
                        }
                    }) {
                        Text("Continue")
                    }
                    .primaryButtonStyle()
                    .padding(.horizontal, StyleGuide.spacing.xl)
                    .padding(.bottom, StyleGuide.spacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Start pulsing animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
            
            Task {
                await fetchPersonalizedResponse()
            }
        }
    }
    
    // MARK: - Supabase Save
    
    private struct OnboardingUpdate: Encodable {
        let username: String
        let growth_goal: String
        let onboarding_completed_at: String
    }
    
    private func saveOnboardingDataToSupabase() async {
        // Get the growth goal from UserDefaults
        guard let growthGoal = UserDefaults.standard.string(forKey: "onboardingGrowthGoal"),
              !growthGoal.isEmpty else {
            print("⚠️ No growth goal to save")
            return
        }
        
        do {
            let userId = try await authManager.supabase.auth.session.user.id
            
            // Generate unique username from first name
            let username = await generateUniqueUsername()
            
            // Create update object
            let update = OnboardingUpdate(
                username: username,
                growth_goal: growthGoal,
                onboarding_completed_at: ISO8601DateFormatter().string(from: Date())
            )
            
            // Update the user's profile with the username, growth goal and completion timestamp
            try await authManager.supabase
                .from("profiles")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ Saved onboarding data to Supabase (username: \(username))")
        } catch {
            print("❌ Failed to save onboarding data to Supabase: \(error)")
            // Continue anyway - data is saved to UserDefaults as fallback
        }
    }
    
    // MARK: - Username Generation
    
    private func generateUniqueUsername() async -> String {
        // Get first name, clean it up for username
        let firstName = (authManager.userFirstName ?? "Friend")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter } // Keep only letters
        
        // Keep trying until we find a unique username
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            // Generate random 4-digit suffix
            let suffix = String(format: "%04d", Int.random(in: 0...9999))
            let candidateUsername = "\(firstName)\(suffix)"
            
            // Check if username is available
            if await isUsernameAvailable(candidateUsername) {
                return candidateUsername
            }
            
            attempts += 1
        }
        
        // Fallback: use UUID suffix if we couldn't find a unique username
        let uuidSuffix = UUID().uuidString.prefix(8).lowercased()
        return "\(firstName)\(uuidSuffix)"
    }
    
    private func isUsernameAvailable(_ username: String) async -> Bool {
        do {
            // Query profiles table to see if username exists
            let response: [UserProfile] = try await authManager.supabase
                .from("profiles")
                .select()
                .eq("username", value: username)
                .execute()
                .value
            
            // Username is available if no results found
            return response.isEmpty
        } catch {
            print("❌ Error checking username availability: \(error)")
            // On error, assume it's not available to be safe
            return false
        }
    }
    
    // UserProfile struct for username checking
    private struct UserProfile: Codable {
        let id: UUID
        let username: String
    }
    
    // MARK: - API Call
    
    private func fetchPersonalizedResponse() async {
        // Get the growth goal from UserDefaults
        let growthGoal = UserDefaults.standard.string(forKey: "onboardingGrowthGoal") ?? "grow spiritually"
        
        // Get user's first name if available
        let firstName = authManager.userFirstName ?? ""
        let nameGreeting = !firstName.isEmpty ? firstName : "friend"
        
        // Create the prompt
        let systemPrompt = """
You are Faith, a warm and compassionate spiritual companion. The user has just shared their spiritual growth goal with you during onboarding. 

Respond with a brief, warm acknowledgment (2-3 sentences max) that:
1. Acknowledges their specific goal with genuine understanding
2. Expresses that you're preparing a personalized experience for them
3. Maintains a tone that is encouraging, personal, and spiritually grounded

Keep it concise, warm, and centered on their journey. Do not use markdown formatting.
"""
        
        let userPrompt = "My spiritual growth goal is: \(growthGoal)"
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        do {
            let session = try await authManager.supabase.auth.session
            let response = try await callBrightProcessor(messages: messages, accessToken: session.accessToken, model: "gpt-4.1-nano")
            
            await MainActor.run {
                responseText = response
                // Delay for typing animation, then show button
                let typingDuration = Double(response.count) * 0.03
                DispatchQueue.main.asyncAfter(deadline: .now() + typingDuration + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
        } catch {
            print("❌ Onboarding API Error: \(error)")
            await MainActor.run {
                responseText = "It's wonderful that you're seeking a deeper understanding of your faith, as this journey can lead to profound personal growth and connection. Give me just a moment while I analyze your responses and customize your Haven experience."
                isLoading = false
            }
        }
    }
    
    private func callBrightProcessor(messages: [[String: String]], accessToken: String, model: String? = nil) async throws -> String {
        struct Body: Encodable { 
            let messages: [[String: String]]
            let model: String?
        }
        struct BrightResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        
        guard let url = URL(string: "https://ppkqyfcnwajfzhvnqxec.supabase.co/functions/v1/bright-processor") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(Body(messages: messages, model: model))
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(BrightResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }
        
        return content
    }
}

// MARK: - Thinking Dots View

private struct ThinkingDotsView: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Text(".")
                    .font(StyleGuide.merriweather(size: 24, weight: .regular))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                    .opacity(index < dotCount ? 1 : 0.3)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

#Preview {
    OnboardingLoadingView(onComplete: {})
        .environmentObject(AuthManager())
}

