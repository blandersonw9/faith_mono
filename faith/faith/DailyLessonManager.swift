//
//  DailyLessonManager.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import Foundation
import Supabase
import Combine
import SwiftUI

// MARK: - Daily Lesson Manager
class DailyLessonManager: ObservableObject {
    @Published var currentLesson: DailyLesson?
    @Published var currentProgress: LessonProgress?
    @Published var state: DailyLessonState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Fetch Today's Lesson
    
    @MainActor
    func fetchTodaysLesson() async {
        isLoading = true
        state = .loading
        errorMessage = nil
        
        do {
            // Try to fetch from Supabase first
            let lesson = try await fetchLessonFromSupabase()
            self.currentLesson = lesson
            self.state = .loaded(lesson)
            await fetchUserProgress(for: lesson.id)
            print("✅ Successfully loaded daily lesson from Supabase")
            
        } catch {
            print("❌ Failed to fetch lesson from Supabase: \(error)")
            
            // Fall back to offline lesson
            let fallbackLesson = FallbackLesson.getTodaysFallback()
            self.currentLesson = fallbackLesson
            self.state = .fallback(fallbackLesson)
            self.errorMessage = error.localizedDescription
            self.currentProgress = createInitialProgress()
            print("🔄 Using fallback lesson: \(fallbackLesson.title)")
        }
        
        isLoading = false
    }
    
    // MARK: - Supabase Fetch
    
    private func fetchLessonFromSupabase() async throws -> DailyLesson {
        print("🔍 Fetching today's lesson from Supabase")
        
        do {
            // Call the get_todays_lesson function
            let response: [DailyLessonResponse] = try await supabase
                .rpc("get_todays_lesson")
                .execute()
                .value
            
            print("📦 Received response with \(response.count) lessons")
            
            guard let lessonData = response.first else {
                print("⚠️ No lesson found in response")
                throw DailyLessonError.noLessonFound
            }
            
            print("✅ Found lesson: \(lessonData.title) with \(lessonData.slides.count) slides")
            
            // Convert the response to our DailyLesson model
            let lesson = try convertResponseToLesson(lessonData)
            print("✅ Successfully converted lesson to model")
            return lesson
            
        } catch {
            print("❌ Detailed error fetching lesson: \(error)")
            print("❌ Error type: \(type(of: error))")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            throw error
        }
    }
    
    private func convertResponseToLesson(_ response: DailyLessonResponse) throws -> DailyLesson {
        // Convert slides from AnyCodable array to LessonSlide objects
        let slides = try response.slides.map { slideData in
            try convertSlideData(slideData)
        }
        
        return DailyLesson(
            id: response.lessonId,
            lessonDate: response.lessonDate,
            title: response.title,
            theme: response.theme,
            description: response.description,
            estimatedDurationMinutes: response.estimatedDurationMinutes,
            slides: slides.sorted { $0.slideIndex < $1.slideIndex },
            createdAt: "", // Not provided by the function
            updatedAt: "" // Not provided by the function
        )
    }
    
    private func convertSlideData(_ slideData: [String: AnyCodable]) throws -> LessonSlide {
        guard let idString = slideData["id"]?.value as? String,
              let id = UUID(uuidString: idString),
              let slideTypeString = slideData["slide_type"]?.value as? String,
              let slideType = SlideType(rawValue: slideTypeString),
              let slideIndex = slideData["slide_index"]?.value as? Int,
              let typeIndex = slideData["type_index"]?.value as? Int,
              let mainText = slideData["main_text"]?.value as? String else {
            throw DailyLessonError.dataParsingError
        }
        
        return LessonSlide(
            id: id,
            slideType: slideType,
            slideIndex: slideIndex,
            typeIndex: typeIndex,
            subtitle: slideData["subtitle"]?.value as? String,
            mainText: mainText,
            verseReference: slideData["verse_reference"]?.value as? String,
            verseText: slideData["verse_text"]?.value as? String,
            audioUrl: slideData["audio_url"]?.value as? String,
            imageUrl: slideData["image_url"]?.value as? String,
            backgroundColor: slideData["background_color"]?.value as? String,
            createdAt: "", // Not provided by the function
            updatedAt: "" // Not provided by the function
        )
    }
    
    // MARK: - User Progress Management
    
    private func fetchUserProgress(for lessonId: UUID) async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            let response: [UserLessonProgress] = try await supabase
                .from("user_lesson_progress")
                .select("*")
                .eq("user_id", value: userId)
                .eq("lesson_id", value: lessonId)
                .execute()
                .value
            
            if let progress = response.first {
                self.currentProgress = convertToLessonProgress(progress)
            } else {
                // Create initial progress if none exists
                self.currentProgress = createInitialProgress()
            }
            
        } catch {
            print("❌ Failed to fetch user progress: \(error)")
            // Create initial progress on error
            self.currentProgress = createInitialProgress()
        }
    }
    
    private func convertToLessonProgress(_ progress: UserLessonProgress) -> LessonProgress {
        let slideTypeProgress: [SlideType: Int] = [:]
        let completedSlides = Set(progress.completedSlides)
        
        return LessonProgress(
            currentSlideIndex: progress.currentSlideIndex,
            totalSlides: currentLesson?.totalSlides ?? 0,
            slideTypeProgress: slideTypeProgress,
            completedSlides: completedSlides,
            isCompleted: progress.isCompleted
        )
    }
    
    private func createInitialProgress() -> LessonProgress {
        let totalSlides = currentLesson?.totalSlides ?? 0
        let slideTypeProgress: [SlideType: Int] = [:]
        
        return LessonProgress(
            currentSlideIndex: 0,
            totalSlides: totalSlides,
            slideTypeProgress: slideTypeProgress,
            completedSlides: Set<Int>(),
            isCompleted: false
        )
    }
    
    // MARK: - Progress Updates
    
    @MainActor
    func updateSlideProgress(to slideIndex: Int, isCompleted: Bool = false) async {
        guard let lessonId = currentLesson?.id else { return }
        
        // Update local progress immediately for responsive UI
        updateLocalProgress(to: slideIndex, isCompleted: isCompleted)
        
        // Skip server update if using fallback lesson
        if isUsingFallback() {
            print("ℹ️ Using fallback lesson - skipping server progress update")
            return
        }
        
        // Update on server in background
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                // Call the update_lesson_progress function
                struct ProgressParams: Codable {
                    let p_lesson_id: String
                    let p_slide_index: Int
                    let p_is_completed: Bool
                }
                
                let params = ProgressParams(
                    p_lesson_id: lessonId.uuidString,
                    p_slide_index: slideIndex,
                    p_is_completed: isCompleted
                )
                
                let response: [String: String] = try await supabase
                    .rpc("update_lesson_progress", params: params)
                    .execute()
                    .value
                
                print("✅ Progress updated successfully")
                
            } catch {
                print("❌ Failed to update progress on server: \(error)")
                // Progress was updated locally, so UI remains responsive
            }
        }
    }
    
    private func updateLocalProgress(to slideIndex: Int, isCompleted: Bool) {
        guard let currentProgress = currentProgress else { return }
        
        var newCompletedSlides = currentProgress.completedSlides
        if isCompleted && !newCompletedSlides.contains(slideIndex) {
            newCompletedSlides.insert(slideIndex)
        }
        
        let isLessonCompleted = isCompleted && slideIndex == (currentProgress.totalSlides - 1)
        
        self.currentProgress = LessonProgress(
            currentSlideIndex: max(currentProgress.currentSlideIndex, slideIndex),
            totalSlides: currentProgress.totalSlides,
            slideTypeProgress: currentProgress.slideTypeProgress,
            completedSlides: newCompletedSlides,
            isCompleted: isLessonCompleted
        )
    }
    
    // MARK: - Navigation Helpers
    
    func canGoToNextSlide() -> Bool {
        guard let progress = currentProgress else { return false }
        return progress.currentSlideIndex < progress.totalSlides - 1
    }
    
    func canGoToPreviousSlide() -> Bool {
        guard let progress = currentProgress else { return false }
        return progress.currentSlideIndex > 0
    }
    
    func goToNextSlide() async {
        guard canGoToNextSlide(), let progress = currentProgress else { return }
        let nextIndex = progress.currentSlideIndex + 1
        await updateSlideProgress(to: nextIndex)
    }
    
    func goToPreviousSlide() async {
        guard canGoToPreviousSlide(), let progress = currentProgress else { return }
        let previousIndex = progress.currentSlideIndex - 1
        await updateSlideProgress(to: previousIndex)
    }
    
    func goToSlide(_ slideIndex: Int) async {
        guard let lesson = currentLesson,
              slideIndex >= 0,
              slideIndex < lesson.totalSlides else { return }
        await updateSlideProgress(to: slideIndex)
    }
    
    // MARK: - Helper Methods
    
    func getCurrentSlide() -> LessonSlide? {
        guard let lesson = currentLesson,
              let progress = currentProgress,
              progress.currentSlideIndex < lesson.slides.count else { return nil }
        return lesson.slides[progress.currentSlideIndex]
    }
    
    func getSlideTypeProgress(_ slideType: SlideType) -> (current: Int, total: Int) {
        guard let lesson = currentLesson else { return (0, 0) }
        let slidesOfType = lesson.slidesByType(slideType)
        let total = slidesOfType.count
        
        guard let progress = currentProgress else { return (0, total) }
        
        // Find current slide index within this type
        let currentSlide = getCurrentSlide()
        let current = currentSlide?.slideType == slideType ? currentSlide?.typeIndex ?? 0 : 0
        
        return (current, total)
    }
    
    func getProgressPercentage() -> Double {
        return currentProgress?.progressPercentage ?? 0.0
    }
    
    func isUsingFallback() -> Bool {
        if case .fallback = state {
            return true
        }
        return false
    }
    
    // MARK: - Refresh
    
    @MainActor
    func refresh() async {
        await fetchTodaysLesson()
    }
}
