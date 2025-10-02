//
//  DailyLessonModels.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import Foundation
import SwiftUI

// MARK: - Daily Lesson Models

struct DailyLesson: Codable, Identifiable {
    let id: UUID
    let lessonDate: String
    let title: String
    let theme: String?
    let description: String?
    let estimatedDurationMinutes: Int
    let slides: [LessonSlide]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case lessonDate = "lesson_date"
        case title
        case theme
        case description
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case slides
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Helper computed property to get formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: lessonDate) else {
            return lessonDate
        }
        
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    // Get slides by type
    func slidesByType(_ type: SlideType) -> [LessonSlide] {
        return slides.filter { $0.slideType == type }
    }
    
    // Get total number of slides
    var totalSlides: Int {
        return slides.count
    }
}

struct LessonSlide: Codable, Identifiable {
    let id: UUID
    let slideType: SlideType
    let slideIndex: Int
    let typeIndex: Int
    let subtitle: String?
    let mainText: String
    let verseReference: String?
    let verseText: String?
    let audioUrl: String?
    let imageUrl: String?
    let backgroundColor: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case slideType = "slide_type"
        case slideIndex = "slide_index"
        case typeIndex = "type_index"
        case subtitle
        case mainText = "main_text"
        case verseReference = "verse_reference"
        case verseText = "verse_text"
        case audioUrl = "audio_url"
        case imageUrl = "image_url"
        case backgroundColor = "background_color"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Helper computed property for background color
    var backgroundUIColor: Color {
        guard let hexColor = backgroundColor else {
            return Color.blue // Default color
        }
        return Color(hex: hexColor)
    }
}

enum SlideType: String, Codable, CaseIterable {
    case scripture = "scripture"
    case devotional = "devotional"
    case prayer = "prayer"
    
    var displayName: String {
        switch self {
        case .scripture: return "Scripture"
        case .devotional: return "Devotional"
        case .prayer: return "Prayer"
        }
    }
    
    var icon: String {
        switch self {
        case .scripture: return "book.fill"
        case .devotional: return "heart.fill"
        case .prayer: return "hands.clap.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .scripture: return .blue
        case .devotional: return .orange
        case .prayer: return .green
        }
    }
}

// MARK: - User Progress Models

struct UserLessonProgress: Codable {
    let id: UUID
    let userId: UUID
    let lessonId: UUID
    let currentSlideIndex: Int
    let completedSlides: [Int]
    let isCompleted: Bool
    let completedAt: String?
    let timeSpentSeconds: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lessonId = "lesson_id"
        case currentSlideIndex = "current_slide_index"
        case completedSlides = "completed_slides"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case timeSpentSeconds = "time_spent_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LessonProgress {
    let currentSlideIndex: Int
    let totalSlides: Int
    let slideTypeProgress: [SlideType: Int] // Current index per type
    let completedSlides: Set<Int>
    let isCompleted: Bool
    
    // Helper computed properties
    var progressPercentage: Double {
        guard totalSlides > 0 else { return 0 }
        return Double(currentSlideIndex + 1) / Double(totalSlides)
    }
    
    var slidesRemaining: Int {
        return totalSlides - (currentSlideIndex + 1)
    }
    
    func isSlideCompleted(_ slideIndex: Int) -> Bool {
        return completedSlides.contains(slideIndex)
    }
}

// MARK: - API Response Models

struct DailyLessonResponse: Codable {
    let lessonId: UUID
    let lessonDate: String
    let title: String
    let theme: String?
    let description: String?
    let estimatedDurationMinutes: Int
    let slides: [[String: AnyCodable]]
    
    enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case lessonDate = "lesson_date"
        case title
        case theme
        case description
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case slides
    }
}

// Helper for handling dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode"))
        }
    }
}

// MARK: - Fallback Lesson System

struct FallbackLesson {
    static let lessons: [DailyLesson] = [
        DailyLesson(
            id: UUID(),
            lessonDate: "2024-01-01",
            title: "God's Love",
            theme: "Love",
            description: "Discover the depth of God's love for you",
            estimatedDurationMinutes: 5,
            slides: [
                LessonSlide(
                    id: UUID(),
                    slideType: .scripture,
                    slideIndex: 0,
                    typeIndex: 0,
                    subtitle: "Today's Scripture",
                    mainText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
                    verseReference: "John 3:16",
                    verseText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
                    audioUrl: nil,
                    imageUrl: nil,
                    backgroundColor: "#4A90E2",
                    createdAt: "2024-01-01T00:00:00Z",
                    updatedAt: "2024-01-01T00:00:00Z"
                ),
                LessonSlide(
                    id: UUID(),
                    slideType: .devotional,
                    slideIndex: 1,
                    typeIndex: 0,
                    subtitle: "Reflection",
                    mainText: "God's love is not conditional or earned. It's given freely to all who believe. Take a moment to reflect on how this truth impacts your daily life and relationships.",
                    verseReference: nil,
                    verseText: nil,
                    audioUrl: nil,
                    imageUrl: nil,
                    backgroundColor: "#F5A623",
                    createdAt: "2024-01-01T00:00:00Z",
                    updatedAt: "2024-01-01T00:00:00Z"
                ),
                LessonSlide(
                    id: UUID(),
                    slideType: .prayer,
                    slideIndex: 2,
                    typeIndex: 0,
                    subtitle: "Prayer Focus",
                    mainText: "Heavenly Father, thank You for Your incredible love. Help me to receive Your love fully and to share it with others. May Your love transform my heart and guide my actions today. Amen.",
                    verseReference: nil,
                    verseText: nil,
                    audioUrl: nil,
                    imageUrl: nil,
                    backgroundColor: "#7ED321",
                    createdAt: "2024-01-01T00:00:00Z",
                    updatedAt: "2024-01-01T00:00:00Z"
                )
            ],
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
    ]
    
    // Get a fallback lesson based on the current day of the year
    static func getTodaysFallback() -> DailyLesson {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let lessonIndex = (dayOfYear - 1) % lessons.count
        return lessons[lessonIndex]
    }
}

// MARK: - Daily Lesson State

enum DailyLessonState {
    case loading
    case loaded(DailyLesson)
    case error(String)
    case fallback(DailyLesson)
}

enum DailyLessonError: LocalizedError {
    case noInternetConnection
    case serverError(String)
    case dataParsingError
    case noLessonFound
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection. Using offline lesson."
        case .serverError(let message):
            return "Server error: \(message). Using offline lesson."
        case .dataParsingError:
            return "Unable to parse lesson data. Using offline lesson."
        case .noLessonFound:
            return "No lesson found for today. Using offline lesson."
        case .invalidResponse:
            return "Invalid response from server. Using offline lesson."
        }
    }
}

