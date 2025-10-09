//
//  CustomStudyModels.swift
//  faith
//
//  Custom Bible Study feature models
//

import Foundation
import SwiftUI

// MARK: - Custom Study Preference Models

struct CustomStudyPreferences: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let goals: [String]
    let topics: [String]
    let minutesPerSession: Int
    let translation: String
    let readingLevel: ReadingLevel
    let includeDiscussionQuestions: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goals
        case topics
        case minutesPerSession = "minutes_per_session"
        case translation
        case readingLevel = "reading_level"
        case includeDiscussionQuestions = "include_discussion_questions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum StudyGoal: String, CaseIterable, Identifiable {
    case dailyHabit = "Build a daily habit"
    case understandJesus = "Understand Jesus"
    case dealWithAnxiety = "Deal with anxiety/peace"
    case prayer = "Grow in prayer"
    case leadership = "Leadership"
    case relationships = "Relationships"
    case wisdom = "Gain wisdom"
    case justiceAndMercy = "Justice & mercy"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .dailyHabit: return "calendar"
        case .understandJesus: return "cross.fill"
        case .dealWithAnxiety: return "heart.fill"
        case .prayer: return "hands.clap.fill"
        case .leadership: return "person.3.fill"
        case .relationships: return "person.2.fill"
        case .wisdom: return "lightbulb.fill"
        case .justiceAndMercy: return "scale.3d"
        }
    }
}

enum StudyTopic: String, CaseIterable, Identifiable {
    case hope = "Hope"
    case identityInChrist = "Identity in Christ"
    case justiceAndMercy = "Justice & Mercy"
    case relationships = "Relationships"
    case leadership = "Leadership"
    case forgiveness = "Forgiveness"
    case suffering = "Suffering"
    case moneyAndWork = "Money & Work"
    case prayer = "Prayer"
    case holiness = "Holiness"
    case mission = "Mission"
    case wisdom = "Wisdom"
    case prophecy = "Prophecy"
    case creation = "Creation"
    case peace = "Peace"
    case trust = "Trust"
    
    var id: String { self.rawValue }
}

enum ReadingLevel: String, CaseIterable, Codable {
    case simple = "simple"
    case conversational = "conversational"
    case scholarly = "scholarly"
    
    var displayName: String {
        switch self {
        case .simple: return "Simple & warm"
        case .conversational: return "Balanced"
        case .scholarly: return "Scholarly"
        }
    }
}

enum StudyTranslation: String, CaseIterable, Identifiable {
    case kjv = "KJV"
    case niv = "NIV"
    case esv = "ESV"
    case nlt = "NLT"
    case csb = "CSB"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .kjv: return "King James Version"
        case .niv: return "New International Version"
        case .esv: return "English Standard Version"
        case .nlt: return "New Living Translation"
        case .csb: return "Christian Standard Bible"
        }
    }
}

// MARK: - Custom Study Models

struct CustomStudy: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let preferenceId: UUID
    let title: String
    let description: String
    let totalUnits: Int
    let completedUnits: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let units: [StudyUnit]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case preferenceId = "preference_id"
        case title
        case description
        case totalUnits = "total_units"
        case completedUnits = "completed_units"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case units
    }
    
    var progressPercentage: Double {
        guard totalUnits > 0 else { return 0 }
        return Double(completedUnits) / Double(totalUnits)
    }
}

struct StudyUnit: Codable, Identifiable {
    let id: UUID
    let studyId: UUID
    let unitIndex: Int
    let unitType: String
    let scope: String
    let title: String
    let estimatedMinutes: Int
    let primaryPassages: [String]
    let sessions: [StudySession]
    let isCompleted: Bool
    let completedAt: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case studyId = "study_id"
        case unitIndex = "unit_index"
        case unitType = "unit_type"
        case scope
        case title
        case estimatedMinutes = "estimated_minutes"
        case primaryPassages = "primary_passages"
        case sessions
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct StudySession: Codable, Identifiable {
    let id: UUID
    let unitId: UUID
    let sessionIndex: Int
    let title: String
    let estimatedMinutes: Int
    let passages: [String]
    let context: String?
    let keyInsights: [String]
    let reflectionQuestions: [String]
    let prayerPrompt: String?
    let actionStep: String?
    let memoryVerse: String?
    let crossReferences: [String]
    let isCompleted: Bool
    let completedAt: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case unitId = "unit_id"
        case sessionIndex = "session_index"
        case title
        case estimatedMinutes = "estimated_minutes"
        case passages
        case context
        case keyInsights = "key_insights"
        case reflectionQuestions = "reflection_questions"
        case prayerPrompt = "prayer_prompt"
        case actionStep = "action_step"
        case memoryVerse = "memory_verse"
        case crossReferences = "cross_references"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle null values in arrays
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        unitId = try container.decode(UUID.self, forKey: .unitId)
        sessionIndex = try container.decode(Int.self, forKey: .sessionIndex)
        title = try container.decode(String.self, forKey: .title)
        estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        
        // Handle arrays with potential null elements
        let rawPassages = try container.decodeIfPresent([String?].self, forKey: .passages) ?? []
        passages = rawPassages.compactMap { $0 }
        
        context = try container.decodeIfPresent(String.self, forKey: .context)
        
        let rawInsights = try container.decodeIfPresent([String?].self, forKey: .keyInsights) ?? []
        keyInsights = rawInsights.compactMap { $0 }
        
        let rawQuestions = try container.decodeIfPresent([String?].self, forKey: .reflectionQuestions) ?? []
        reflectionQuestions = rawQuestions.compactMap { $0 }
        
        prayerPrompt = try container.decodeIfPresent(String.self, forKey: .prayerPrompt)
        actionStep = try container.decodeIfPresent(String.self, forKey: .actionStep)
        memoryVerse = try container.decodeIfPresent(String.self, forKey: .memoryVerse)
        
        let rawRefs = try container.decodeIfPresent([String?].self, forKey: .crossReferences) ?? []
        crossReferences = rawRefs.compactMap { $0 }
        
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

// MARK: - Intake State

struct CustomStudyIntakeState {
    var selectedGoals: Set<StudyGoal> = []
    var selectedTopics: Set<StudyTopic> = []
    var customTopics: [String] = []
    var minutesPerSession: Int = 15
    var selectedTranslation: StudyTranslation = .niv
    var readingLevel: ReadingLevel = .conversational
    var includeDiscussionQuestions: Bool = true
    
    var isValid: Bool {
        return !selectedGoals.isEmpty && (!selectedTopics.isEmpty || !customTopics.isEmpty)
    }
    
    var allTopics: [String] {
        return selectedTopics.map { $0.rawValue } + customTopics
    }
    
    func toPreferences(userId: UUID) -> CustomStudyPreferences {
        return CustomStudyPreferences(
            id: UUID(),
            userId: userId,
            goals: selectedGoals.map { $0.rawValue },
            topics: allTopics,
            minutesPerSession: minutesPerSession,
            translation: selectedTranslation.rawValue,
            readingLevel: readingLevel,
            includeDiscussionQuestions: includeDiscussionQuestions,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

