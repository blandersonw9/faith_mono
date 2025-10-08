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
    @State private var selectedOptions: Set<String> = []
    @FocusState private var isTextFieldFocused: Bool
    
    // Growth options
    private let growthOptions = [
        "Build a daily Scripture habit",
        "Grow in prayer & conversation with God",
        "Find peace in anxiety/stress",
        "Understand the Bible better",
        "Hear God's direction / discern next steps",
        "Strength for temptation & self-control",
        "Forgive or repair a relationship",
        "Hope & joy in a hard season",
        "Community & accountability",
        "Grief & comfort"
    ]
    
    var body: some View {
        ZStack {
            // Background
            StyleGuide.backgroundBeige
                .ignoresSafeArea()
            
            ScrollView {
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
                    .padding(.top, StyleGuide.spacing.xl)
                    .padding(.horizontal, StyleGuide.spacing.xl)
                    
                    // Chip buttons
                    FlowLayout(spacing: 8) {
                        ForEach(growthOptions, id: \.self) { option in
                            ChipButton(
                                title: option,
                                isSelected: selectedOptions.contains(option)
                            ) {
                                toggleOption(option)
                            }
                        }
                    }
                    .padding(.horizontal, StyleGuide.spacing.xl)
                    .padding(.top, StyleGuide.spacing.md)
                    
                    // Spacer for vertical centering when content is small
                    Spacer()
                        .frame(minHeight: 40)
                    
                    VStack(spacing: StyleGuide.spacing.md) {
                        // Text input field (optional)
                        TextField("Or share something else...", text: $growthAnswer)
                            .font(StyleGuide.merriweather(size: 16, weight: .regular))
                            .foregroundColor(StyleGuide.mainBrown)
                            .focused($isTextFieldFocused)
                            .padding(StyleGuide.spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(StyleGuide.gold.opacity(0.4), lineWidth: 1.5)
                            )
                        
                        // Next button
                        Button(action: {
                            completeStep()
                        }) {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!selectedOptions.isEmpty || !growthAnswer.isEmpty ? false : true)
                        .opacity((!selectedOptions.isEmpty || !growthAnswer.isEmpty) ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, StyleGuide.spacing.xl)
                    .padding(.bottom, StyleGuide.spacing.xl)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Actions
    
    private func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
    }
    
    private func completeStep() {
        // Combine selected chips and custom text
        var allGoals: [String] = Array(selectedOptions)
        
        let trimmedAnswer = growthAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAnswer.isEmpty {
            allGoals.append(trimmedAnswer)
        }
        
        if !allGoals.isEmpty {
            // Save as comma-separated string
            let goalsString = allGoals.joined(separator: ", ")
            UserDefaults.standard.set(goalsString, forKey: "onboardingGrowthGoal")
        }
        
        onContinue()
    }
}

// MARK: - Chip Button Component

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(StyleGuide.merriweather(size: 14, weight: .regular))
                .foregroundColor(isSelected ? .white : StyleGuide.mainBrown)
                .padding(.horizontal, StyleGuide.spacing.md)
                .padding(.vertical, StyleGuide.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? StyleGuide.gold : Color.white.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? StyleGuide.gold : StyleGuide.gold.opacity(0.4), lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Flow Layout for Wrapping Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

#Preview {
    OnboardingGrowthView(onContinue: {})
        .environmentObject(AuthManager())
}

