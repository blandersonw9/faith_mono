//
//  NotificationManager.swift
//  faith
//
//  Handles daily push notifications to remind users to complete their daily lesson
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // Notification identifiers
    private let dailyReminderIdentifier = "daily-lesson-reminder"
    
    // Default notification time (9:00 AM)
    private let defaultHour = 9
    private let defaultMinute = 0
    
    // Track if today's lesson is completed (updated from outside)
    private var isTodayLessonCompleted = false
    
    // References to other managers for checking completion status
    private weak var dailyLessonManager: DailyLessonManager?
    private weak var userDataManager: UserDataManager?
    
    override init() {
        super.init()
        print("📱 NotificationManager init started")
        // Defer authorization check to avoid blocking initialization
        DispatchQueue.main.async { [weak self] in
            print("📱 NotificationManager checking authorization")
            self?.checkAuthorizationStatus()
        }
        print("📱 NotificationManager init completed")
    }
    
    // MARK: - Authorization
    
    /// Check the current authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
                print("📱 Notification authorization status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    /// Request permission to send notifications
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                print("✅ Notification permission granted")
                // Schedule the daily reminder immediately after getting permission
                await scheduleDailyReminder()
            } else {
                print("❌ Notification permission denied")
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule a daily reminder notification
    /// Note: This schedules a repeating notification. To make it conditional on lesson completion,
    /// call updateNotificationBasedOnLessonStatus() after checking lesson status
    func scheduleDailyReminder(hour: Int? = nil, minute: Int? = nil) async {
        // Cancel any existing daily reminders first
        cancelDailyReminder()
        
        let authorized = await MainActor.run { self.isAuthorized }
        guard authorized else {
            print("⚠️ Cannot schedule notification - not authorized")
            return
        }
        
        let reminderHour = hour ?? defaultHour
        let reminderMinute = minute ?? defaultMinute
        
        // Get a varied notification message
        let (title, body) = getRandomNotificationMessage()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add custom data to identify this notification
        content.userInfo = ["type": "daily-lesson-reminder"]
        
        // Create date components for the trigger
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        // Create the trigger - repeats daily at the specified time
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Daily reminder scheduled for \(reminderHour):\(String(format: "%02d", reminderMinute))")
            
            // Test notification only in debug builds
            #if DEBUG
            print("🧪 Debug mode: scheduling test notification for 10 seconds")
            await scheduleTestNotification()
            #else
            print("🚀 Production mode: test notifications disabled")
            #endif
        } catch {
            print("❌ Error scheduling daily reminder: \(error)")
        }
    }
    
    /// Set references to other managers for checking completion status
    func setManagers(dailyLessonManager: DailyLessonManager, userDataManager: UserDataManager) {
        self.dailyLessonManager = dailyLessonManager
        self.userDataManager = userDataManager
        print("📱 NotificationManager connected to lesson and user managers")
    }
    
    /// Check if today's lesson is completed
    @MainActor
    func checkTodayLessonStatus() async -> Bool {
        guard let dailyLessonManager = dailyLessonManager else { return false }
        
        // Check if current lesson is loaded and completed
        if let progress = dailyLessonManager.currentProgress {
            return progress.isCompleted
        }
        
        // If no progress, lesson hasn't been started
        return false
    }
    
    /// Check if user has completed any activity today (broader check)
    @MainActor
    func checkTodayActivityStatus() async -> Bool {
        guard let userDataManager = userDataManager else { return false }
        
        let today = Calendar.current.startOfDay(for: Date())
        return userDataManager.isDateCompleted(today)
    }
    
    /// Update lesson completion status and manage notifications accordingly
    @MainActor
    func updateLessonCompletionStatus(isCompleted: Bool) {
        isTodayLessonCompleted = isCompleted
        
        if isCompleted {
            // Lesson completed - clear badge and update status
            print("✅ Lesson completed - clearing badge")
            clearBadge()
            // Note: We keep the daily reminder scheduled for future days
        } else {
            print("ℹ️ Lesson not completed - notification will be sent at scheduled time")
        }
    }
    
    /// Schedule smart notifications based on user's streak and completion status
    @MainActor
    func scheduleSmartNotifications() async {
        guard isAuthorized else { return }
        
        // Check if today's lesson is already completed
        let lessonCompleted = await checkTodayLessonStatus()
        let activityCompleted = await checkTodayActivityStatus()
        
        if lessonCompleted || activityCompleted {
            print("✅ Today's activity already completed - no reminder needed")
            clearBadge()
            return
        }
        
        // Get user's streak to customize messaging
        var streakCount = 0
        if let userDataManager = userDataManager {
            streakCount = userDataManager.getCurrentStreak()
        }
        
        if streakCount > 3 {
            // User has a streak - use streak-specific reminder
            await scheduleStreakReminder(streakCount: streakCount)
        } else {
            // Regular reminder
            let (hour, minute) = getReminderTime()
            await scheduleDailyReminder(hour: hour, minute: minute)
        }
    }
    
    /// Schedule a smart notification that checks lesson status before delivery
    /// This uses UNNotificationServiceExtension approach (requires extension - advanced)
    /// For now, we use simple daily repeating notifications
    func scheduleSmartDailyReminder(hour: Int? = nil, minute: Int? = nil) async {
        // For simplicity, we're using repeating notifications
        // To make it truly conditional, you would need:
        // 1. A notification service extension
        // 2. Or check completion status and schedule individual notifications each day
        // For now, schedule the daily reminder
        await scheduleDailyReminder(hour: hour, minute: minute)
    }
    
    /// Schedule a test notification (debug only) - fires 10 seconds from now
    #if DEBUG
    private func scheduleTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Daily notifications are working! This test will only appear in debug mode."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Test notification scheduled for 10 seconds from now")
        } catch {
            print("❌ Error scheduling test notification: \(error)")
        }
    }
    #endif
    
    // MARK: - Cancel Notifications
    
    /// Cancel the daily reminder notification
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [dailyReminderIdentifier]
        )
        print("🗑️ Cancelled daily reminder notifications")
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all pending notifications")
    }
    
    // MARK: - Update Reminder Time
    
    /// Update the time for the daily reminder
    func updateReminderTime(hour: Int, minute: Int) async {
        // Save the new time to UserDefaults
        UserDefaults.standard.set(hour, forKey: "notificationHour")
        UserDefaults.standard.set(minute, forKey: "notificationMinute")
        
        // Reschedule with new time
        await scheduleDailyReminder(hour: hour, minute: minute)
        print("✅ Updated reminder time to \(hour):\(String(format: "%02d", minute))")
    }
    
    /// Get the current reminder time from UserDefaults or defaults
    func getReminderTime() -> (hour: Int, minute: Int) {
        let hour = UserDefaults.standard.object(forKey: "notificationHour") as? Int ?? defaultHour
        let minute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? defaultMinute
        return (hour, minute)
    }
    
    // MARK: - Badge Management
    
    /// Clear the app badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
        print("🔔 Badge cleared")
    }
    
    // MARK: - Check Scheduled Notifications
    
    /// Print all pending notifications (useful for debugging)
    func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Pending notifications: \(requests.count)")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("    Trigger: \(trigger.dateComponents)")
            }
        }
    }
    
    // MARK: - Notification Variations
    
    /// Get a random notification message for variety
    private func getRandomNotificationMessage() -> (title: String, body: String) {
        let messages: [(String, String)] = [
            ("Your Daily Lesson Awaits ✝️", "Take a few minutes to grow in faith with today's lesson"),
            ("Time for Your Daily Lesson 🙏", "Your spiritual growth journey continues today"),
            ("Daily Faith Reminder 📖", "Discover today's lesson and deepen your faith"),
            ("Let's Grow Together 🌱", "Your daily lesson is ready. Take a moment with God today"),
            ("Faith Check-In ✨", "Continue your journey with today's inspiring lesson"),
            ("Your Spiritual Moment ⛪", "Today's lesson is here to inspire and guide you"),
            ("Daily Devotional Time 💫", "Start or end your day with today's faith lesson"),
            ("Don't Break Your Streak! 🔥", "Keep your momentum going with today's lesson"),
            ("A Moment with God 🕊️", "Your daily lesson is waiting for you")
        ]
        
        return messages.randomElement() ?? messages[0]
    }
    
    // MARK: - Customization
    
    /// Schedule notifications at multiple times per day (e.g., morning and evening reminders)
    func scheduleMultipleReminders(times: [(hour: Int, minute: Int)]) async {
        let authorized = await MainActor.run { self.isAuthorized }
        guard authorized else {
            print("⚠️ Cannot schedule notifications - not authorized")
            return
        }
        
        cancelDailyReminder()
        
        for (index, time) in times.enumerated() {
            let (title, body) = getRandomNotificationMessage()
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.badge = 1
            content.userInfo = ["type": "daily-lesson-reminder"]
            
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(dailyReminderIdentifier)-\(index)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Reminder \(index + 1) scheduled for \(time.hour):\(String(format: "%02d", time.minute))")
            } catch {
                print("❌ Error scheduling reminder \(index + 1): \(error)")
            }
        }
    }
    
    /// Schedule a streak reminder (use when user has a streak to maintain)
    func scheduleStreakReminder(streakCount: Int, hour: Int? = nil, minute: Int? = nil) async {
        let reminderHour = hour ?? defaultHour
        let reminderMinute = minute ?? defaultMinute
        
        // Cancel existing reminders first
        cancelDailyReminder()
        
        let content = UNMutableNotificationContent()
        
        // Customize message based on streak length
        if streakCount >= 30 {
            content.title = "Amazing \(streakCount)-Day Streak! 🏆"
            content.body = "You're a faith champion! Don't let this incredible streak end today"
        } else if streakCount >= 14 {
            content.title = "Impressive \(streakCount)-Day Streak! 🌟"
            content.body = "Two weeks strong! Keep your momentum going with today's lesson"
        } else if streakCount >= 7 {
            content.title = "One Week Streak! 🔥"
            content.body = "You're building an amazing habit. Complete today's lesson!"
        } else {
            content.title = "Don't Break Your \(streakCount)-Day Streak! 🔥"
            content.body = "You're on fire! Complete today's lesson to keep your streak alive"
        }
        
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "streak-reminder", "streakCount": streakCount]
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier, // Use same ID so it replaces regular reminders
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Streak reminder scheduled for \(streakCount)-day streak")
        } catch {
            print("❌ Error scheduling streak reminder: \(error)")
        }
    }
    
    // MARK: - Advanced Customization
    
    /// Schedule evening reminder if morning was missed
    @MainActor
    func scheduleEveningReminderIfNeeded() async {
        let lessonCompleted = await checkTodayLessonStatus()
        let activityCompleted = await checkTodayActivityStatus()
        
        guard !lessonCompleted && !activityCompleted else {
            print("✅ Activity already completed - no evening reminder needed")
            return
        }
        
        // Schedule for 7:00 PM if not completed by then
        let eveningHour = 19
        let eveningMinute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Evening Faith Check-In 🌙"
        content.body = "End your day with today's lesson. Just a few minutes for your soul"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "evening-reminder"]
        
        var dateComponents = DateComponents()
        dateComponents.hour = eveningHour
        dateComponents.minute = eveningMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "evening-reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Evening reminder scheduled for \(eveningHour):\(String(format: "%02d", eveningMinute))")
        } catch {
            print("❌ Error scheduling evening reminder: \(error)")
        }
    }
    
    /// Get notification preferences from UserDefaults
    func getNotificationPreferences() -> NotificationPreferences {
        return NotificationPreferences(
            isEnabled: isAuthorized,
            primaryTime: getReminderTime(),
            enableStreakReminders: UserDefaults.standard.bool(forKey: "enableStreakReminders"),
            enableEveningReminders: UserDefaults.standard.bool(forKey: "enableEveningReminders"),
            enableWeekendReminders: UserDefaults.standard.bool(forKey: "enableWeekendReminders")
        )
    }
    
    /// Save notification preferences
    @MainActor
    func saveNotificationPreferences(_ prefs: NotificationPreferences) async {
        UserDefaults.standard.set(prefs.enableStreakReminders, forKey: "enableStreakReminders")
        UserDefaults.standard.set(prefs.enableEveningReminders, forKey: "enableEveningReminders")
        UserDefaults.standard.set(prefs.enableWeekendReminders, forKey: "enableWeekendReminders")
        
        // Reschedule notifications based on new preferences
        await scheduleSmartNotifications()
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences {
    let isEnabled: Bool
    let primaryTime: (hour: Int, minute: Int)
    let enableStreakReminders: Bool
    let enableEveningReminders: Bool
    let enableWeekendReminders: Bool
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Called when a notification is received while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when the user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String, type == "daily-lesson-reminder" {
            print("📱 User tapped daily lesson notification")
            // Post notification to navigate to daily lesson
            NotificationCenter.default.post(name: .openDailyLesson, object: nil)
        }
        
        // Clear the badge when user interacts with notification
        DispatchQueue.main.async {
            self.clearBadge()
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openDailyLesson = Notification.Name("openDailyLesson")
    static let openFriendsManager = Notification.Name("openFriendsManager")
}
