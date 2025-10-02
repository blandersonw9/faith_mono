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

// MARK: - User Data Manager

class UserDataManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userProgress: UserProgress?
    @Published var dailyCompletions: [DailyCompletion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    weak var authManager: AuthManager?
    
    init(supabase: SupabaseClient, authManager: AuthManager? = nil) {
        self.supabase = supabase
        self.authManager = authManager
    }
    
    // MARK: - Fetch All User Data
    
    @MainActor
    func fetchUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            // Fetch all data concurrently
            async let profileTask = fetchProfile(userId: userId)
            async let progressTask = fetchProgress(userId: userId)
            async let completionsTask = fetchDailyCompletions(userId: userId)
            
            let (profile, progress, completions) = try await (profileTask, progressTask, completionsTask)
            
            self.userProfile = profile
            self.userProgress = progress
            self.dailyCompletions = completions
            
            print("✅ Loaded user data:")
            print("   Profile: \(profile.display_name)")
            print("   Current streak: \(progress?.current_streak ?? 0)")
            print("   Daily completions: \(completions.count)")
            
        } catch {
            print("❌ Error fetching user data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
}

