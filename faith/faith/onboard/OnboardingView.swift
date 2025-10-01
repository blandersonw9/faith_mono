//
//  OnboardingView.swift
//  faith
//
//  Created by Blake Anderson on 9/30/25.
//

import SwiftUI

struct GlowingHalo: View {
    let progress: Double // 0.0 to 1.0
    
    var body: some View {
        ZStack {
            // Outer glow layers
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            StyleGuide.gold.opacity(0.4 * progress),
                            StyleGuide.gold.opacity(0.15 * progress),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 30,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .blur(radius: 12)
            
            // Middle glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            StyleGuide.gold.opacity(0.6 * progress),
                            StyleGuide.gold.opacity(0.25 * progress),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 8)
            
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            StyleGuide.gold.opacity(0.3 * progress),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
                .blur(radius: 4)
            
            // Cross Icon in the center
            Image("crossFill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 45, height: 45)
                .foregroundColor(StyleGuide.gold)
        }
        .animation(.easeInOut(duration: 0.8), value: progress)
    }
}

struct AnimatedTypingText: View {
    let fullText: String
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    
    @State private var displayedText: String = ""
    @State private var opacity: Double = 0
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.leading)
            .lineSpacing(lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(opacity)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        displayedText = ""
        opacity = 1
        
        let characters = Array(fullText)
        var currentIndex = 0
        
        func typeNext() {
            guard currentIndex < characters.count else { return }
            
            withAnimation(.easeOut(duration: 0.15)) {
                displayedText.append(characters[currentIndex])
            }
            currentIndex += 1
            
            // Use varying delays for a more natural flow
            let baseDelay: Double = 0.03
            let randomVariation = Double.random(in: -0.01...0.015)
            let delay = baseDelay + randomVariation
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }
        
        typeNext()
    }
}

struct OnboardingWelcomeView: View {
    @EnvironmentObject var authManager: AuthManager
    let onContinue: () -> Void
    
    @State private var gratitudeText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var haloProgress: Double = 0.33 // First page of 3 (page 1, page 2, loading)
    
    var body: some View {
        ZStack {
            // Background
            StyleGuide.backgroundBeige
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 80)
                
                // Glowing Halo
                GlowingHalo(progress: haloProgress)
                
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
                    onContinue()
                }) {
                    Text("Begin")
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
            return "Hi \(firstName)—I'm Faith, your spiritual companion. I'm here to walk with you. In under a minute, I'll shape a plan just for you."
        } else {
            return "Hi there—I'm Faith, your spiritual companion. I'm here to walk with you. In under a minute, I'll shape a plan just for you."
        }
    }
    
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
        .environmentObject(AuthManager())
}
