//
//  OnboardingGrowthView.swift
//  faith
//
//  Created by Blake Anderson on 9/30/25.
//

import SwiftUI

struct OnboardingGrowthView: View {
    @EnvironmentObject var authManager: AuthManager
    let onContinue: () -> Void
    
    @State private var growthAnswer: String = ""
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
                
                // Glowing Halo (66% progress for page 2 of 3)
                GlowingHalo(progress: 0.66)
                
                // Question Text
                VStack(spacing: StyleGuide.spacing.lg) {
                    AnimatedTypingText(
                        fullText: "How would you like to grow in your spiritual journey right now?",
                        font: StyleGuide.merriweather(size: 22, weight: .regular),
                        color: StyleGuide.mainBrown,
                        lineSpacing: 8
                    )
                    .multilineTextAlignment(.center)
                }
                .padding(.top, StyleGuide.spacing.xxl)
                .padding(.horizontal, StyleGuide.spacing.xl)
                
                Spacer()
                
                // Text input field
                HStack(spacing: StyleGuide.spacing.sm) {
                    TextField("Share how you'd like to grow...", text: $growthAnswer)
                        .font(StyleGuide.merriweather(size: 16, weight: .regular))
                        .foregroundColor(StyleGuide.mainBrown)
                        .focused($isTextFieldFocused)
                    
                    if !growthAnswer.isEmpty {
                        Button(action: {
                            completeStep()
                        }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(StyleGuide.gold)
                        }
                    }
                }
                .padding(StyleGuide.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(StyleGuide.gold.opacity(0.4), lineWidth: 1.5)
                )
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
    
    // MARK: - Actions
    
    private func completeStep() {
        // Save the growth answer
        let trimmedAnswer = growthAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAnswer.isEmpty {
            UserDefaults.standard.set(trimmedAnswer, forKey: "onboardingGrowthGoal")
        }
        
        onContinue()
    }
}

#Preview {
    OnboardingGrowthView(onContinue: {})
        .environmentObject(AuthManager())
}

