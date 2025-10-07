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

struct VerseNote: Codable, Identifiable, Equatable {
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

struct SavedVerse: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID
    let book: Int
    let chapter: Int
    let verse: Int
    let verse_text: String
    let translation: String?
    let created_at: String
    
    var verseReference: String {
        let bookName = BibleManager.bookNames[book] ?? "Unknown"
        return "\(bookName) \(chapter):\(verse)"
    }
    
    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: created_at) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Fallback
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
    @Published var savedVerses: [SavedVerse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshDate = Date() // Force UI updates
    @Published var hasLoadedInitialData = false // Track if we've loaded data at least once
    
    nonisolated(unsafe) private let supabase: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    weak var authManager: AuthManager?
    private var isFetchingData = false // Prevent duplicate concurrent fetches
    
    init(supabase: SupabaseClient, authManager: AuthManager? = nil) {
        self.supabase = supabase
        self.authManager = authManager
    }
    
    // MARK: - Fetch All User Data
    
    @MainActor
    func fetchUserData() async {
        // Prevent duplicate concurrent fetches
        guard !isFetchingData else {
            print("⚠️ fetchUserData already in progress, skipping duplicate request")
            return
        }
        
        print("🔄 Starting fetchUserData...")
        isFetchingData = true
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
            async let savedVersesTask = fetchSavedVerses(userId: userId)
            
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
                // Keep existing data on error - don't clear
            }
            
            // Fetch completions (optional)
            do {
                let completions = try await completionsTask
                self.dailyCompletions = completions
            } catch {
                print("⚠️ Completions not found (optional): \(error.localizedDescription)")
                // Keep existing data on error - don't clear
            }
            
            // Fetch notes (critical for this feature)
            do {
                let notes = try await notesTask
                self.verseNotes = notes
                print("✅ Verse notes: \(notes.count)")
            } catch {
                print("⚠️ Notes fetch error: \(error.localizedDescription)")
                // Keep existing data on error - don't clear
            }
            
            // Fetch saved verses (optional)
            do {
                let verses = try await savedVersesTask
                self.savedVerses = verses
                print("✅ Saved verses: \(verses.count)")
            } catch {
                print("⚠️ Saved verses fetch error: \(error.localizedDescription)")
                // Keep existing data on error - don't clear
            }
            
            print("✅ Finished loading user data successfully")
            
            // Mark that we've loaded data at least once
            await MainActor.run {
                self.hasLoadedInitialData = true
            }
            
        } catch {
            print("❌ Error getting auth session: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
        
        // Update refresh date to force UI updates
        await MainActor.run {
            self.lastRefreshDate = Date()
        }
        
        isLoading = false
        isFetchingData = false
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
        // First try username from profile (generated during onboarding)
        if let username = userProfile?.username, !username.isEmpty {
            return username
        }
        // Then try display_name
        if let displayName = userProfile?.display_name, !displayName.isEmpty {
            return displayName
        }
        // Then authManager firstName
        if let firstName = authManager?.userFirstName, !firstName.isEmpty {
            return firstName
        }
        // Fallback to UserDefaults in case authManager reference is weak/nil
        if let savedFirstName = UserDefaults.standard.string(forKey: "userFirstName"), !savedFirstName.isEmpty {
            return savedFirstName
        }
        return "Friend"
    }
    
    func getFirstName() -> String {
        // Get first name for personalized greetings (used in HomeView)
        if let firstName = authManager?.userFirstName, !firstName.isEmpty {
            return firstName
        }
        // Fallback to UserDefaults in case authManager reference is weak/nil
        if let savedFirstName = UserDefaults.standard.string(forKey: "userFirstName"), !savedFirstName.isEmpty {
            return savedFirstName
        }
        // Try display_name as fallback
        if let displayName = userProfile?.display_name, !displayName.isEmpty {
            return displayName
        }
        return "Friend"
    }
    
    func getCurrentStreak() -> Int {
        return userProgress?.current_streak ?? 0
    }
    
    // MARK: - Profile Update Methods
    
    func updateProfile(username: String, firstName: String) async throws {
        let userId = try await supabase.auth.session.user.id
        
        struct ProfileUpdate: Encodable {
            let username: String
            let display_name: String
        }
        
        let update = ProfileUpdate(username: username, display_name: firstName)
        
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
        
        print("✅ Profile updated successfully")
        
        // Refresh user data to get updated profile
        await fetchUserData()
    }
    
    func isUsernameAvailable(_ username: String) async -> Bool {
        do {
            let response: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: username)
                .execute()
                .value
            
            return response.isEmpty
        } catch {
            print("❌ Error checking username availability: \(error)")
            return false
        }
    }
    
    func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: startOfDay)
        
        return dailyCompletions.contains { completion in
            completion.completion_date.starts(with: dateString)
        }
    }
    
    func getWeekDayStates() -> [DayState] {
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        // Get start of current week (Sunday)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysToSubtract = weekday - 1 // Sunday is 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfToday)!
        
        var states: [DayState] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                states.append(.incomplete)
                continue
            }
            
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isCompleted = isDateCompleted(date)
            
            // Show completed state if the day is done, even if it's today
            if isCompleted {
                states.append(.complete)
            } else if isToday {
                // Show current state only if today is not yet completed
                states.append(.current)
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
        
        // Get today's date in user's local timezone
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let localDateString = dateFormatter.string(from: today)
        
        // Wrap in Task to avoid MainActor isolation issues
        try await Task {
            // Define structs locally within the task
            struct UpdateProgressParams: Codable {
                let p_activity_type: String
                let p_xp_earned: Int
                let p_completion_date: String
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
                    p_xp_earned: xpEarned,
                    p_completion_date: localDateString
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
    
    // MARK: - Saved Verses Methods
    
    private func fetchSavedVerses(userId: UUID) async throws -> [SavedVerse] {
        print("💾 Fetching saved verses for user: \(userId)")
        let response: [SavedVerse] = try await supabase
            .from("saved_verses")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("💾 Fetched \(response.count) saved verses")
        return response
    }
    
    @MainActor
    func saveVerse(book: Int, chapter: Int, verse: Int, verseText: String, translation: String?) async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        // Check if already saved
        if isVerseSaved(book: book, chapter: chapter, verse: verse, translation: translation) {
            print("⚠️ Verse already saved")
            return
        }
        
        struct VerseSaveInsert: Encodable {
            let user_id: UUID
            let book: Int
            let chapter: Int
            let verse: Int
            let verse_text: String
            let translation: String?
        }
        
        let saveData = VerseSaveInsert(
            user_id: userId,
            book: book,
            chapter: chapter,
            verse: verse,
            verse_text: verseText,
            translation: translation
        )
        
        let response: [SavedVerse] = try await supabase
            .from("saved_verses")
            .insert(saveData)
            .select()
            .execute()
            .value
        
        // Add to local array
        if let newSavedVerse = response.first {
            savedVerses.insert(newSavedVerse, at: 0)
        }
        
        print("✅ Saved verse: \(BibleManager.bookNames[book] ?? "Unknown") \(chapter):\(verse)")
    }
    
    @MainActor
    func unsaveVerse(book: Int, chapter: Int, verse: Int, translation: String?) async throws {
        // Find the saved verse to delete
        guard let savedVerse = savedVerses.first(where: { 
            $0.book == book && $0.chapter == chapter && $0.verse == verse && $0.translation == translation 
        }) else {
            print("⚠️ Verse not found in saved verses")
            return
        }
        
        try await supabase
            .from("saved_verses")
            .delete()
            .eq("id", value: savedVerse.id.uuidString)
            .execute()
        
        // Remove from local array
        savedVerses.removeAll { $0.id == savedVerse.id }
        
        print("✅ Unsaved verse: \(BibleManager.bookNames[book] ?? "Unknown") \(chapter):\(verse)")
    }
    
    func isVerseSaved(book: Int, chapter: Int, verse: Int, translation: String?) -> Bool {
        return savedVerses.contains { savedVerse in
            savedVerse.book == book && 
            savedVerse.chapter == chapter && 
            savedVerse.verse == verse && 
            savedVerse.translation == translation
        }
    }
    
    // MARK: - Account Deletion
    
    @MainActor
    func deleteAccount() async throws {
        print("🗑️ Starting account deletion process...")
        
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        // Delete all user data in order
        // 1. Delete saved verses
        try await supabase
            .from("saved_verses")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Deleted saved verses")
        
        // 2. Delete verse notes
        try await supabase
            .from("verse_notes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Deleted verse notes")
        
        // 3. Delete daily completions
        try await supabase
            .from("daily_completions")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Deleted daily completions")
        
        // 4. Delete user progress
        try await supabase
            .from("user_progress")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Deleted user progress")
        
        // 5. Delete profile
        try await supabase
            .from("profiles")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()
        print("✅ Deleted profile")
        
        // Clear local data
        await MainActor.run {
            self.userProfile = nil
            self.userProgress = nil
            self.dailyCompletions = []
            self.verseNotes = []
            self.savedVerses = []
        }
        
        print("✅ Account data deleted successfully")
    }
}

