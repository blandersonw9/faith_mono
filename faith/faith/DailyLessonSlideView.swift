//
//  DailyLessonSlideView.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI

// MARK: - Daily Lesson Slide View
struct DailyLessonSlideView: View {
    @ObservedObject var dailyLessonManager: DailyLessonManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentSlideIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ZStack {
                // Background - full screen beige
                StyleGuide.backgroundBeige
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top bar with close button and progress
                    HStack(spacing: 12) {
                        Button(action: { 
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Snapchat-style progress bars
                        if let lesson = dailyLessonManager.currentLesson {
                            HStack(spacing: 2) {
                                ForEach(0..<lesson.slides.count, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(index < currentSlideIndex ? 
                                              Color.white : 
                                              index == currentSlideIndex ? 
                                              Color.white.opacity(0.8) : 
                                              Color.white.opacity(0.3))
                                        .frame(height: 2)
                                        .frame(maxWidth: .infinity)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentSlideIndex = index
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: screenWidth * 0.6)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    
                    // Main content area - direct layout on screen
                    if let lesson = dailyLessonManager.currentLesson,
                       currentSlideIndex < lesson.slides.count {
                        let slide = lesson.slides[currentSlideIndex]
                        
                        ZStack {
                            // Content laid directly on screen
                            VStack(spacing: 0) {
                                Spacer()
                                
                                // Slide type indicator
                                HStack {
                                    Image(systemName: slide.slideType.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(slide.slideType.color)
                                    
                                    Text(slide.slideType.displayName.uppercased())
                                        .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                                        .foregroundColor(slide.slideType.color)
                                        .tracking(1.2)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 40)
                                .padding(.bottom, 20)
                                
                                // Subtitle
                                if let subtitle = slide.subtitle {
                                    Text(subtitle)
                                        .font(StyleGuide.merriweather(size: 28, weight: .bold))
                                        .foregroundColor(StyleGuide.mainBrown)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.horizontal, 40)
                                        .padding(.bottom, 30)
                                }
                                
                                // Main content
                                Text(slide.mainText)
                                    .font(StyleGuide.merriweather(size: 20, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .lineSpacing(8)
                                    .padding(.horizontal, 40)
                                
                                // Verse reference
                                if let verseReference = slide.verseReference {
                                    VStack(spacing: 16) {
                                        Rectangle()
                                            .fill(StyleGuide.mainBrown.opacity(0.2))
                                            .frame(height: 1)
                                            .padding(.horizontal, 40)
                                            .padding(.top, 30)
                                        
                                        Text("— \(verseReference)")
                                            .font(StyleGuide.merriweather(size: 16, weight: .regular))
                                            .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.3), value: currentSlideIndex)
                    }
                    
                    Spacer()
                    
                    // Bottom navigation - arrows on either end
                    HStack {
                        // Left arrow
                        Button(action: {
                            goToPreviousSlide()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(canGoToPreviousSlide() ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                )
                        }
                        .disabled(!canGoToPreviousSlide())
                        
                        Spacer()
                        
                        // Right arrow
                        Button(action: {
                            goToNextSlide()
                        }) {
                            Image(systemName: canGoToNextSlide() ? "chevron.right" : "checkmark")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(canGoToNextSlide() ? StyleGuide.mainBrown : StyleGuide.gold)
                                )
                        }
                        .disabled(!canGoToNextSlide())
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentSlideIndex = dailyLessonManager.currentProgress?.currentSlideIndex ?? 0
        }
    }
    
    private func canGoToPreviousSlide() -> Bool {
        return currentSlideIndex > 0
    }
    
    private func canGoToNextSlide() -> Bool {
        guard let lesson = dailyLessonManager.currentLesson else { return false }
        return currentSlideIndex < lesson.slides.count - 1
    }
    
    private func goToPreviousSlide() {
        guard canGoToPreviousSlide() else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSlideIndex -= 1
        }
        
        Task {
            await dailyLessonManager.goToSlide(currentSlideIndex)
        }
    }
    
    private func goToNextSlide() {
        if canGoToNextSlide() {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSlideIndex += 1
            }
            
            Task {
                await dailyLessonManager.goToSlide(currentSlideIndex)
            }
        } else {
            // Lesson completed
            Task {
                await dailyLessonManager.updateSlideProgress(
                    to: currentSlideIndex,
                    isCompleted: true
                )
            }
        }
    }
}

