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
    @State private var imageLoaded: Bool = false
    @State private var preloadedImages: [Int: UIImage] = [:] // Cache of preloaded images by slide index
    
    // Get background image URL for current slide (deterministic based on slide index)
    private var currentBackgroundImageURL: String? {
        guard !dailyLessonManager.backgroundImageURLs.isEmpty else {
            return nil
        }
        let index = currentSlideIndex % dailyLessonManager.backgroundImageURLs.count
        return dailyLessonManager.backgroundImageURLs[index]
    }
    
    // Get preloaded image for current slide
    private var currentPreloadedImage: UIImage? {
        return preloadedImages[currentSlideIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ZStack {
                // Background - solid black so rounded top corners reveal black under header
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                   
                    // Only show content when image is loaded
                    if imageLoaded {
                        // Subtitle under bar at top-left
                        if let lesson = dailyLessonManager.currentLesson,
                           currentSlideIndex < lesson.slides.count {
                            let slide = lesson.slides[currentSlideIndex]
                            if let subtitle = slide.subtitle, !subtitle.isEmpty {
                                HStack {
                                    Text(subtitle)
                                        .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Color.black.opacity(0.35)
                                        .blur(radius: 20)
                                )
                                .padding(.top, 24)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                                
                                // Main content with readable background
                                VStack(spacing: 20) {
                                    // Main text
                                    BasicMarkdownText(text: slide.mainText, enableLinking: false, textColor: .white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 20)
                                    
                                    // Verse reference
                                    if let verseReference = slide.verseReference {
                                        VStack(spacing: 12) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.4))
                                                .frame(height: 1)
                                                .padding(.horizontal, 24)
                                            
                                            Text("— \(verseReference)")
                                                .font(StyleGuide.merriweather(size: 16, weight: .regular))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 24)
                                                .padding(.bottom, 16)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.4))
                                        .blur(radius: 30)
                                )
                                .padding(.horizontal, 20)
                                
                                Spacer()
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom navigation - symmetric circular buttons with share in the middle
                    if imageLoaded {
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
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
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
                // Round only the top corners of the main content with background image
                .background(
                    ZStack {
                        // Background image - use preloaded image if available, otherwise AsyncImage
                        Group {
                            if let cachedImage = currentPreloadedImage {
                                // Use cached image for instant loading
                                Image(uiImage: cachedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else if let imageURL = currentBackgroundImageURL, let url = URL(string: imageURL) {
                                // Fallback to AsyncImage if not yet cached
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        StyleGuide.backgroundBeige
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        StyleGuide.backgroundBeige
                                    @unknown default:
                                        StyleGuide.backgroundBeige
                                    }
                                }
                            } else {
                                // Fallback if no URL available
                                StyleGuide.backgroundBeige
                            }
                        }
                        
                        // Light overlay for depth
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.15),
                                Color.clear,
                                Color.black.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea()
                )
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
            imageLoaded = false
            
            print("🎬 Daily lesson appeared. Background URLs count: \(dailyLessonManager.backgroundImageURLs.count)")
            
            // Preload all images for this lesson
            preloadLessonImages()
            
            // Fallback: show content after 1 second even if image hasn't loaded
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    if !imageLoaded {
                        print("⚠️ Image load timeout - showing content anyway")
                        withAnimation {
                            imageLoaded = true
                        }
                    }
                }
            }
        }
        .onChange(of: currentSlideIndex) { _ in
            // Keep content visible during slide transitions
            // Don't reset imageLoaded - this prevents black flashes
            print("📱 Slide changed to index: \(currentSlideIndex)")
        }
    }
    
    // MARK: - Image Preloading
    
    private func preloadLessonImages() {
        guard let lesson = dailyLessonManager.currentLesson,
              !dailyLessonManager.backgroundImageURLs.isEmpty else {
            print("⚠️ No lesson or background URLs to preload")
            imageLoaded = true
            return
        }
        
        let totalSlides = lesson.slides.count
        print("🖼️ Preloading images for \(totalSlides) slides...")
        
        Task {
            var loadedCount = 0
            
            // Preload images for each slide
            for slideIndex in 0..<totalSlides {
                let imageIndex = slideIndex % dailyLessonManager.backgroundImageURLs.count
                let urlString = dailyLessonManager.backgroundImageURLs[imageIndex]
                
                // Skip if already loaded
                if preloadedImages[slideIndex] != nil {
                    continue
                }
                
                // Download image
                if let url = URL(string: urlString),
                   let (data, _) = try? await URLSession.shared.data(from: url),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        preloadedImages[slideIndex] = uiImage
                        loadedCount += 1
                        
                        // Show content once first image is loaded
                        if slideIndex == currentSlideIndex && !imageLoaded {
                            withAnimation {
                                imageLoaded = true
                            }
                        }
                        
                        print("✅ Preloaded image \(loadedCount)/\(totalSlides)")
                    }
                } else {
                    print("❌ Failed to preload image for slide \(slideIndex)")
                }
            }
            
            await MainActor.run {
                print("🎉 Preloading complete! Loaded \(loadedCount)/\(totalSlides) images")
                if !imageLoaded {
                    imageLoaded = true
                }
            }
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
                // Dismiss the view after marking as completed
                await MainActor.run {
                    dismiss()
                }
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
        let shareView = ShareLessonContentView(
            slide: slide, 
            backgroundImage: currentPreloadedImage,
            backgroundImageURL: currentBackgroundImageURL
        )
            .frame(width: targetWidth, height: targetHeight)

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
    let backgroundImage: UIImage?
    let backgroundImageURL: String?
    
    var body: some View {
        ZStack {
            // Background - full screen image with overlay
            ZStack {
                Group {
                    if let cachedImage = backgroundImage {
                        // Use preloaded image
                        Image(uiImage: cachedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let imageURL = backgroundImageURL, let url = URL(string: imageURL) {
                        // Fallback to AsyncImage
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                StyleGuide.backgroundBeige
                            }
                        }
                    } else {
                        StyleGuide.backgroundBeige
                    }
                }
                
                // Light overlay for depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.15),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Subtitle under bar at top-left (exact copy from main view)
                if let subtitle = slide.subtitle, !subtitle.isEmpty {
                    HStack {
                        Text(subtitle)
                            .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Color.black.opacity(0.35)
                            .blur(radius: 20)
                    )
                    .padding(.top, 24)
                }
                
                // Main content area - direct layout on screen (exact copy)
                ZStack {
                    // Content laid directly on screen
                    VStack(spacing: 0) {
                        Spacer(minLength: 12)
                        
                        // Main content with readable background
                        VStack(spacing: 20) {
                            // Main text
                            BasicMarkdownText(text: slide.mainText, enableLinking: false, textColor: .white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                            
                            // Verse reference
                            if let verseReference = slide.verseReference {
                                VStack(spacing: 12) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(height: 1)
                                        .padding(.horizontal, 24)
                                    
                                    Text("— \(verseReference)")
                                        .font(StyleGuide.merriweather(size: 16, weight: .regular))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 16)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.4))
                                .blur(radius: 30)
                        )
                        .padding(.horizontal, 20)
                        
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

