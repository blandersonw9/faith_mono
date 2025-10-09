//
//  CustomStudyCardView.swift
//  faith
//
//  Display custom Bible study card
//

import SwiftUI
import Foundation

struct CustomStudyCardView: View {
    let study: CustomStudy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            Color(hex: "#8B7355"),
                            Color(hex: "#6B5644")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle pattern overlay
                    Color.white.opacity(0.05)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Title
                        Text(study.title)
                            .font(StyleGuide.merriweather(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Description
                        if !study.description.isEmpty {
                            Text(study.description)
                                .font(StyleGuide.merriweather(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        // Progress bar and stats
                        VStack(spacing: 8) {
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(StyleGuide.gold)
                                        .frame(width: geo.size.width * CGFloat(study.progressPercentage), height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            // Stats row
                            HStack {
                                Label("\(study.completedUnits)/\(study.totalUnits) units", systemImage: "book.fill")
                                    .font(StyleGuide.merriweather(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct GeneratingStudyCard: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        StyleGuide.gold.opacity(0.3),
                        StyleGuide.mainBrown.opacity(0.2),
                        StyleGuide.gold.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .hueRotation(.degrees(animationPhase * 30))
                
                VStack(spacing: 16) {
                    // Animated book icon
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 48))
                        .foregroundColor(StyleGuide.gold)
                        .opacity(0.8 + Double(sin(Double(animationPhase * 2))) * 0.2)
                    
                    VStack(spacing: 8) {
                        Text("Generating Your Study...")
                            .font(StyleGuide.merriweather(size: 18, weight: .bold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        Text("Creating a personalized 10-part Bible study")
                            .font(StyleGuide.merriweather(size: 13, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                            .multilineTextAlignment(.center)
                        
                        // Animated dots
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(StyleGuide.gold)
                                    .frame(width: 8, height: 8)
                                    .opacity(0.3 + Double(sin(Double(animationPhase * 3 + CGFloat(index) * 0.5))) * 0.7)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(StyleGuide.gold.opacity(0.3)), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 2 * .pi
            }
        }
    }
}

struct ActiveCustomStudySection: View {
    @EnvironmentObject var customStudyManager: CustomStudyManager
    @State private var showStudyDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show loading skeleton if generating
            if customStudyManager.isGenerating {
                // Section header
                HStack {
                    Text("Your Custom Study")
                        .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                    
                    Spacer()
                }
                
                // Loading skeleton card
                GeneratingStudyCard()
                
            } else if let study = customStudyManager.currentStudy {
                // Section header
                HStack {
                    Text("Your Custom Study")
                        .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                    
                    Spacer()
                    
                    if study.completedUnits >= study.totalUnits {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(StyleGuide.gold)
                            .font(.system(size: 16))
                    }
                }
                
                // Study card
                CustomStudyCardView(study: study) {
                    showStudyDetail = true
                }
            }
        }
        .sheet(isPresented: $showStudyDetail) {
            if let study = customStudyManager.currentStudy {
                CustomStudyDetailView(study: study)
                    .environmentObject(customStudyManager)
            }
        }
        .onAppear {
            // Fetch is already handled in HomeView, no need to fetch again
        }
    }
}

