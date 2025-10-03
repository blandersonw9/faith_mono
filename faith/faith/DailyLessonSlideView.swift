//
//  DailyLessonSlideView.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Daily Lesson Slide View
struct DailyLessonSlideView: View {
    @ObservedObject var dailyLessonManager: DailyLessonManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentSlideIndex: Int = 0
    @State private var showingShareSheet: Bool = false
    @State private var hideChromeForShare: Bool = false
    @State private var shareImage: UIImage? = nil
    @State private var contentFrame: CGRect = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ZStack {
                // Background - solid black so rounded top corners reveal black under header
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                   

                    // Subtitle under bar at top-left
                    if let lesson = dailyLessonManager.currentLesson,
                       currentSlideIndex < lesson.slides.count {
                        let slide = lesson.slides[currentSlideIndex]
                        if let subtitle = slide.subtitle, !subtitle.isEmpty {
                            HStack {
                                Text(subtitle)
                                    .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                                    .foregroundColor(StyleGuide.mainBrown)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                    }
                    
                    // Main content area - direct layout on screen
                    if let lesson = dailyLessonManager.currentLesson,
                       currentSlideIndex < lesson.slides.count {
                        let slide = lesson.slides[currentSlideIndex]
                        
                        ZStack {
                            // Content laid directly on screen
                            VStack(spacing: 0) {
                                Spacer(minLength: 12)
                                
                                // Main content styled like chat markdown renderer
                                BasicMarkdownText(text: slide.mainText, enableLinking: false)
                                    .padding(.horizontal, 16)
                                
                                // Verse reference
                                if let verseReference = slide.verseReference {
                                    VStack(spacing: 16) {
                                        Rectangle()
                                            .fill(StyleGuide.mainBrown.opacity(0.2))
                                            .frame(height: 1)
                                            .padding(.horizontal, 24)
                                            .padding(.top, 30)
                                        
                                        Text("— \(verseReference)")
                                            .font(StyleGuide.merriweather(size: 16, weight: .regular))
                                            .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                            .multilineTextAlignment(.leading)
                                            .padding(.horizontal, 24)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom navigation - symmetric circular buttons with share in the middle
                    HStack {
                        Button(action: { goToPreviousSlide() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(StyleGuide.mainBrown.opacity(0.18), lineWidth: 1))
                                .opacity(canGoToPreviousSlide() ? 1.0 : 0.45)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canGoToPreviousSlide())

                        Spacer()

                        Button(action: { captureAndShare() }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(StyleGuide.mainBrown.opacity(0.18), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: { goToNextSlide() }) {
                            Image(systemName: canGoToNextSlide() ? "chevron.right" : "checkmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(StyleGuide.mainBrown.opacity(0.18), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .contentShape(Rectangle())
                    .opacity(hideChromeForShare ? 0 : 1)
                    .allowsHitTesting(!hideChromeForShare)
                }
                // Tap left/right to navigate like stories
                .overlay(
                    Group {
                        if !hideChromeForShare {
                            HStack(spacing: 0) {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture { goToPreviousSlide(triggerHaptic: true) }
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture { goToNextSlide(triggerHaptic: true) }
                            }
                            // Leave space for the bottom control bar so taps reach buttons
                            .padding(.bottom, 110)
                        }
                    }
                )
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.height > 80 { dismiss() }
                            else if value.translation.width > 60 { goToPreviousSlide() }
                            else if value.translation.width < -60 { goToNextSlide() }
                        }
                )
                // Round only the top corners of the main content
                .background(StyleGuide.backgroundBeige)
                .clipShape(TopRoundedCorner(radius: 20))
                // Track the on-screen frame of the main content for cropping the share image
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ContentFramePreferenceKey.self, value: proxy.frame(in: .global))
                    }
                )
                .onPreferenceChange(ContentFramePreferenceKey.self) { rect in
                    contentFrame = rect
                }
            }
        }
        .safeAreaInset(edge: .top) {
            ZStack(alignment: .bottom) {
                Color.black
                    .ignoresSafeArea(edges: .top)
                if let lesson = dailyLessonManager.currentLesson {
                    HStack(spacing: 6) {
                        ForEach(0..<lesson.slides.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index <= currentSlideIndex ? Color.white : Color.white.opacity(0.28))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }
            .frame(height: 80)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ActivityView(activityItems: [image])
            }
        }
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
    
    private func goToPreviousSlide(triggerHaptic: Bool = false) {
        guard canGoToPreviousSlide() else { return }
        if triggerHaptic { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        currentSlideIndex -= 1
        
        Task {
            await dailyLessonManager.goToSlide(currentSlideIndex)
        }
    }
    
    private func goToNextSlide(triggerHaptic: Bool = false) {
        if canGoToNextSlide() {
            if triggerHaptic { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            currentSlideIndex += 1
            
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

    // MARK: - Text Formatting helpers
    private func formattedMainText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        // Bold first sentence (until first period)
        if let firstPeriod = text.firstIndex(of: ".") {
            let lower = text.startIndex
            let upper = text.index(after: firstPeriod)
            if let asRange = Range(lower..<upper, in: attributed) {
                attributed[asRange].font = StyleGuide.merriweather(size: 20, weight: .bold)
            }
        }
        // Italicize quoted phrases
        let openingQuotes: [Character] = ["\"", "“", "‘"]
        let closingQuotes: [Character] = ["\"", "”", "’"]
        let pairs: [(Character, Character)] = Array(zip(openingQuotes, closingQuotes))
        for (open, close) in pairs {
            var startSearch = text.startIndex
            while let openIdx = text[startSearch...].firstIndex(of: open),
                  let closeIdx = text[text.index(after: openIdx)...].firstIndex(of: close) {
                let inner = text.index(after: openIdx)..<closeIdx
                if let asRange = Range(inner, in: attributed) {
                    attributed[asRange].inlinePresentationIntent = .emphasized
                }
                startSearch = text.index(after: closeIdx)
            }
        }
        return attributed
    }

    // MARK: - Share Helpers
    private func captureAndShare() {
        // Render an off-screen SwiftUI view (no header, no rounded corners)
        guard let lesson = dailyLessonManager.currentLesson,
              currentSlideIndex < lesson.slides.count else { return }
        let slide = lesson.slides[currentSlideIndex]

        // Build the share view with explicit screen dimensions
        let screenSize = UIScreen.main.bounds.size
        let targetWidth = screenSize.width
        let targetHeight = screenSize.height
        let shareView = ShareLessonContentView(slide: slide)
            .frame(width: targetWidth, height: targetHeight)
            .background(StyleGuide.backgroundBeige)

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareView)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                self.shareImage = uiImage
                self.showingShareSheet = true
            }
        } else {
            // Fallback: do not share on < iOS 16 in this path
        }
    }
}

// MARK: - Custom top-corners shape
fileprivate struct TopRoundedCorner: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, min(rect.width, rect.height) / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// Preference key for tracking content frame
fileprivate struct ContentFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Offscreen share view (no header, no rounded corners)
fileprivate struct ShareLessonContentView: View {
    let slide: LessonSlide
    
    var body: some View {
        ZStack {
            // Background - full screen beige
            StyleGuide.backgroundBeige
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Subtitle under bar at top-left (exact copy from main view)
                HStack {
                    Text(slide.subtitle ?? "")
                        .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Main content area - direct layout on screen (exact copy)
                ZStack {
                    // Content laid directly on screen
                    VStack(spacing: 0) {
                        Spacer(minLength: 12)
                        
                        // Main content styled like chat markdown renderer
                        BasicMarkdownText(text: slide.mainText, enableLinking: false)
                            .padding(.horizontal, 16)
                        
                        // Verse reference
                        if let verseReference = slide.verseReference {
                            VStack(spacing: 16) {
                                Rectangle()
                                    .fill(StyleGuide.mainBrown.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 30)
                                
                                Text("— \(verseReference)")
                                    .font(StyleGuide.merriweather(size: 16, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Share sheet wrapper
fileprivate struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

