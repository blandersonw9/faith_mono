//
//  UserDataManager.swift
//  faith
//
//  Manages user profile and progress data from Supabase
//

import Foundation
import SwiftUI
import Supabase
import Combine

// MARK: - Data Models

struct UserProfile: Codable {
    let id: UUID
    let username: String
    let display_name: String
    let profile_picture_url: String?
    let growth_goal: String?
    let created_at: String?
    let updated_at: String?
}

struct UserProgress: Codable {
    let id: UUID
    let user_id: UUID
    let current_streak: Int
    let longest_streak: Int
    let total_xp: Int
    let current_level: Int
    let last_activity_date: String?
}

struct DailyCompletion: Codable {
    let id: UUID
    let user_id: UUID
    let completion_date: String
    let activity_type: String
    let xp_earned: Int
}

struct VerseNote: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let book: Int
    let chapter: Int
    let verse: Int
    let note_text: String
    let translation: String?
    let created_at: String
    let updated_at: String
    
    var verseReference: String {
        let bookName = BibleManager.bookNames[book] ?? "Unknown"
        return "\(bookName) \(chapter):\(verse)"
    }
    
    var formattedDate: String {
        // Try parsing with fractional seconds first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: created_at) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Fallback to standard format without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: created_at) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return "Recently"
    }
    
    var relativeDate: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: created_at) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Fallback
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: created_at) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        return "Just now"
    }
}

// MARK: - User Data Manager

class UserDataManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userProgress: UserProgress?
    @Published var dailyCompletions: [DailyCompletion] = []
    @Published var verseNotes: [VerseNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    nonisolated(unsafe) private let supabase: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    weak var authManager: AuthManager?
    
    init(supabase: SupabaseClient, authManager: AuthManager? = nil) {
        self.supabase = supabase
        self.authManager = authManager
    }
    
    // MARK: - Fetch All User Data
    
    @MainActor
    func fetchUserData() async {
        print("🔄 Starting fetchUserData...")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Getting auth session...")
            let session = try await supabase.auth.session
            let userId = session.user.id
            print("🔄 User ID: \(userId)")
            
            // Fetch all data independently - don't let one failure stop others
            async let profileTask = fetchProfile(userId: userId)
            async let progressTask = fetchProgress(userId: userId)
            async let completionsTask = fetchDailyCompletions(userId: userId)
            async let notesTask = fetchVerseNotes(userId: userId)
            
            // Fetch profile (optional - app works without it)
            do {
                let profile = try await profileTask
                self.userProfile = profile
                print("✅ Profile: \(profile.display_name)")
            } catch {
                print("⚠️ Profile not found (optional): \(error.localizedDescription)")
                self.userProfile = nil
            }
            
            // Fetch progress (optional)
            do {
                let progress = try await progressTask
                self.userProgress = progress
                print("✅ Current streak: \(progress?.current_streak ?? 0)")
            } catch {
                print("⚠️ Progress not found (optional): \(error.localizedDescription)")
                self.userProgress = nil
            }
            
            // Fetch completions (optional)
            do {
                let completions = try await completionsTask
                self.dailyCompletions = completions
                print("✅ Daily completions: \(completions.count)")
            } catch {
                print("⚠️ Completions not found (optional): \(error.localizedDescription)")
                self.dailyCompletions = []
            }
            
            // Fetch notes (critical for this feature)
            do {
                let notes = try await notesTask
                self.verseNotes = notes
                print("✅ Verse notes: \(notes.count)")
            } catch {
                print("⚠️ Notes fetch error: \(error.localizedDescription)")
                self.verseNotes = []
            }
            
            print("✅ Finished loading user data successfully")
            
        } catch {
            print("❌ Error getting auth session: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("🔄 Finished fetchUserData")
    }
    
    // MARK: - Individual Fetch Methods
    
    private func fetchProfile(userId: UUID) async throws -> UserProfile {
        let response: [UserProfile] = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw NSError(domain: "UserDataManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }
        
        return profile
    }
    
    private func fetchProgress(userId: UUID) async throws -> UserProgress? {
        let response: [UserProgress] = try await supabase
            .from("user_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return response.first
    }
    
    private func fetchDailyCompletions(userId: UUID) async throws -> [DailyCompletion] {
        // Get completions for the last 7 days
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let startDate = dateFormatter.string(from: sevenDaysAgo)
        
        let response: [DailyCompletion] = try await supabase
            .from("daily_completions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("completion_date", value: startDate)
            .order("completion_date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Helper Methods
    
    func getDisplayName() -> String {
        // First try profile display_name, then authManager firstName, then UserDefaults, then default
        if let displayName = userProfile?.display_name, !displayName.isEmpty {
            print("👤 Using profile display name: \(displayName)")
            return displayName
        }
        if let firstName = authManager?.userFirstName, !firstName.isEmpty {
            print("👤 Using authManager first name: \(firstName)")
            return firstName
        }
        // Fallback to UserDefaults in case authManager reference is weak/nil
        if let savedFirstName = UserDefaults.standard.string(forKey: "userFirstName"), !savedFirstName.isEmpty {
            print("👤 Using saved first name from UserDefaults: \(savedFirstName)")
            return savedFirstName
        }
        print("👤 Falling back to 'Friend' - no first name found")
        return "Friend"
    }
    
    func getCurrentStreak() -> Int {
        return userProgress?.current_streak ?? 0
    }
    
    func isDateCompleted(_ date: Date) -> Bool {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)
        
        return dailyCompletions.contains { completion in
            completion.completion_date.starts(with: dateString)
        }
    }
    
    func getWeekDayStates() -> [DayState] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of current week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // Sunday is 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        
        var states: [DayState] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                states.append(.incomplete)
                continue
            }
            
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isPast = date < calendar.startOfDay(for: today)
            let isCompleted = isDateCompleted(date)
            
            if isToday {
                states.append(.current)
            } else if isCompleted {
                states.append(.complete)
            } else {
                states.append(.incomplete)
            }
        }
        
        return states
    }
    
    // MARK: - Update Methods
    
    @MainActor
    func updateProgressAndStreak(activityType: String = "daily_practice", xpEarned: Int = 10) async throws {
        print("🔄 Updating progress and streak for activity: \(activityType)")
        
        // Wrap in Task to avoid MainActor isolation issues
        try await Task {
            // Define structs locally within the task
            struct UpdateProgressParams: Codable {
                let p_activity_type: String
                let p_xp_earned: Int
            }
            
            struct UpdateProgressResponse: Codable {
                let success: Bool
                let current_streak: Int?
                let longest_streak: Int?
                let total_xp: Int?
                let current_level: Int?
                let xp_earned: Int?
                let message: String?
                let error: String?
            }
            
            do {
                let params = UpdateProgressParams(
                    p_activity_type: activityType,
                    p_xp_earned: xpEarned
                )
                
                let response: UpdateProgressResponse = try await supabase
                    .rpc("update_progress", params: params)
                    .execute()
                    .value
                
                if response.success {
                    print("✅ Progress updated successfully!")
                    if let streak = response.current_streak {
                        print("🔥 Current streak: \(streak)")
                    }
                    if let xp = response.total_xp {
                        print("⭐ Total XP: \(xp)")
                    }
                } else {
                    let errorMsg = response.error ?? "Unknown error"
                    print("⚠️ Progress update failed: \(errorMsg)")
                    if !errorMsg.contains("already completed") {
                        throw NSError(domain: "UserDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                    }
                }
            } catch {
                print("❌ Error calling update_progress: \(error)")
                throw error
            }
        }.value
        
        // Refresh user data on MainActor to update UI
        await fetchUserData()
    }
    
    @MainActor
    func markTodayComplete(activityType: String = "daily_practice") async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: today)
        
        // Check if already completed today
        if isDateCompleted(today) {
            print("⚠️ Already completed today")
            return
        }
        
        struct CompletionInsert: Encodable {
            let user_id: UUID
            let completion_date: String
            let activity_type: String
            let xp_earned: Int
        }
        
        let completion = CompletionInsert(
            user_id: userId,
            completion_date: dateString,
            activity_type: activityType,
            xp_earned: 10
        )
        
        try await supabase
            .from("daily_completions")
            .insert(completion)
            .execute()
        
        print("✅ Marked today as complete")
        
        // Refresh data
        await fetchUserData()
    }
    
    // MARK: - Verse Notes Methods
    
    private func fetchVerseNotes(userId: UUID) async throws -> [VerseNote] {
        print("📝 Fetching verse notes for user: \(userId)")
        let response: [VerseNote] = try await supabase
            .from("verse_notes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("📝 Fetched \(response.count) verse notes")
        return response
    }
    
    @MainActor
    func addVerseNote(book: Int, chapter: Int, verse: Int, noteText: String, translation: String?) async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        struct NoteInsert: Encodable {
            let user_id: UUID
            let book: Int
            let chapter: Int
            let verse: Int
            let note_text: String
            let translation: String?
        }
        
        let note = NoteInsert(
            user_id: userId,
            book: book,
            chapter: chapter,
            verse: verse,
            note_text: noteText,
            translation: translation
        )
        
        let response: [VerseNote] = try await supabase
            .from("verse_notes")
            .insert(note)
            .select()
            .execute()
            .value
        
        // Add to local array
        if let newNote = response.first {
            verseNotes.insert(newNote, at: 0)
        }
        
        print("✅ Added verse note for \(BibleManager.bookNames[book] ?? "Unknown") \(chapter):\(verse)")
    }
    
    @MainActor
    func updateVerseNote(noteId: UUID, noteText: String) async throws {
        struct NoteUpdate: Encodable {
            let note_text: String
        }
        
        let update = NoteUpdate(note_text: noteText)
        
        try await supabase
            .from("verse_notes")
            .update(update)
            .eq("id", value: noteId.uuidString)
            .execute()
        
        // Update local array
        if let index = verseNotes.firstIndex(where: { $0.id == noteId }) {
            // Refresh the specific note
            let response: [VerseNote] = try await supabase
                .from("verse_notes")
                .select()
                .eq("id", value: noteId.uuidString)
                .execute()
                .value
            
            if let updatedNote = response.first {
                verseNotes[index] = updatedNote
            }
        }
        
        print("✅ Updated verse note")
    }
    
    @MainActor
    func deleteVerseNote(noteId: UUID) async throws {
        try await supabase
            .from("verse_notes")
            .delete()
            .eq("id", value: noteId.uuidString)
            .execute()
        
        // Remove from local array
        verseNotes.removeAll { $0.id == noteId }
        
        print("✅ Deleted verse note")
    }
    
    func getNotesForVerse(book: Int, chapter: Int, verse: Int) -> [VerseNote] {
        return verseNotes.filter { note in
            note.book == book && note.chapter == chapter && note.verse == verse
        }
    }
}

