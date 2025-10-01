//
//  OnboardingView.swift
//  faith
//
//  Created by Blake Anderson on 9/30/25.
//

import SwiftUI

struct AnimatedTypingText: View {
    let fullText: String
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    
    @State private var visibleCharacters: Int = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(fullText.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(font)
                    .foregroundColor(color)
                    .opacity(index < visibleCharacters ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: visibleCharacters)
            }
        }
        .multilineTextAlignment(.leading)
        .lineSpacing(lineSpacing)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            startTyping()
        }
    }
    
    private func startTyping() {
        visibleCharacters = 0
        typeNextCharacter()
    }
    
    private func typeNextCharacter() {
        guard visibleCharacters < fullText.count else { return }
        
        visibleCharacters += 1
        
        // Use varying delays for a more natural flow
        let baseDelay: Double = 0.035
        let randomVariation = Double.random(in: -0.01...0.015)
        let delay = baseDelay + randomVariation
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            typeNextCharacter()
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var gratitudeText: String = ""
    @State private var isCompleted: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            StyleGuide.backgroundBeige
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 80)
                
                // Cross Icon
                Image("crossFill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(StyleGuide.gold)
                
                // Greeting Text
                VStack(spacing: StyleGuide.spacing.lg) {
                    AnimatedTypingText(
                        fullText: greetingText,
                        font: StyleGuide.merriweather(size: 22, weight: .regular),
                        color: StyleGuide.mainBrown,
                        lineSpacing: 8
                    )
                }
                .padding(.top, StyleGuide.spacing.xxl)
                .padding(.horizontal, StyleGuide.spacing.xl)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("Continue")
                }
                .primaryButtonStyle()
                .padding(.horizontal, StyleGuide.spacing.xl)
                .padding(.bottom, StyleGuide.spacing.xl)
            }
        }
        .onAppear {
            // Auto-focus the text field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingText: String {
        if let firstName = authManager.userFirstName, !firstName.isEmpty {
            return "Hi \(firstName)—I'm Faith, your companion. I'm here to walk with you. I'll ask a few quick questions to understand your journey and tailor your experience. Everything you share stays private."
        } else {
            return "Hi there—I'm Faith, your companion. I'm here to walk with you. I'll ask a few quick questions to understand your journey and tailor your experience. Everything you share stays private."
        }
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        // Save gratitude if provided
        if !gratitudeText.isEmpty {
            UserDefaults.standard.set(gratitudeText, forKey: "onboardingGratitude")
        }
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isCompleted = true
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
}
