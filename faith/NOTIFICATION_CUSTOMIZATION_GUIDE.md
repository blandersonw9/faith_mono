# Smart Notification System - Customization Guide

## 🎉 What's Now Available

Your Faith app now has a **smart notification system** that:
- ✅ Only sends notifications if daily lesson isn't completed
- ✅ Uses streak-based messaging for motivated users
- ✅ Clears badges when lessons are completed
- ✅ Supports multiple reminder times
- ✅ Has customizable notification preferences
- ✅ Includes evening reminders as backup

## 🧠 Smart Features

### 1. Lesson Completion Detection
```swift
// Automatically checks if today's lesson is completed
await notificationManager.checkTodayLessonStatus()

// Also checks broader daily activity completion
await notificationManager.checkTodayActivityStatus()
```

### 2. Streak-Based Messaging
Notifications adapt based on user's streak:

**7+ days:** "One Week Streak! 🔥"
**14+ days:** "Impressive 14-Day Streak! 🌟" 
**30+ days:** "Amazing 30-Day Streak! 🏆"

### 3. Automatic Badge Management
- Badge appears when notification is sent
- Badge clears when user completes lesson
- Badge clears when app becomes active

## 🎛️ Customization Options

### Multiple Daily Reminders
```swift
// Schedule morning and evening reminders
await notificationManager.scheduleMultipleReminders(times: [
    (hour: 9, minute: 0),   // 9:00 AM
    (hour: 20, minute: 0)   // 8:00 PM
])
```

### Evening Backup Reminders
```swift
// Schedule evening reminder if lesson not completed by 7 PM
await notificationManager.scheduleEveningReminderIfNeeded()
```

### Custom Notification Messages
The system randomly selects from these messages:
- "Your Daily Lesson Awaits ✝️"
- "Time for Your Daily Lesson 🙏"
- "Daily Faith Reminder 📖"
- "Let's Grow Together 🌱"
- "Faith Check-In ✨"
- "Your Spiritual Moment ⛪"
- "Daily Devotional Time 💫"
- "Don't Break Your Streak! 🔥"
- "A Moment with God 🕊️"

### Notification Preferences
```swift
struct NotificationPreferences {
    let isEnabled: Bool
    let primaryTime: (hour: Int, minute: Int)
    let enableStreakReminders: Bool
    let enableEveningReminders: Bool
    let enableWeekendReminders: Bool
}

// Get current preferences
let prefs = notificationManager.getNotificationPreferences()

// Save new preferences
await notificationManager.saveNotificationPreferences(newPrefs)
```

## 🔄 How It Works

### 1. App Launch
```
1. App loads → NotificationManager initializes
2. Connects to DailyLessonManager and UserDataManager
3. Checks if today's lesson is completed
4. Schedules appropriate notification (regular or streak-based)
```

### 2. Lesson Completion
```
1. User completes final slide
2. DailyLessonSlideView calls notificationManager.updateLessonCompletionStatus(true)
3. Badge is cleared immediately
4. Tomorrow's notification remains scheduled
```

### 3. Daily Check (9:00 AM default)
```
1. iOS delivers notification
2. User sees reminder
3. Taps notification → Opens daily lesson
4. Completes lesson → Badge clears
```

## 🛠️ Advanced Customization

### Add to Settings/Profile View
```swift
NavigationLink {
    NotificationSettingsView()
        .environmentObject(notificationManager)
} label: {
    HStack {
        Image(systemName: "bell.badge")
        Text("Notifications")
        Spacer()
        if notificationManager.isAuthorized {
            Text("On")
                .foregroundColor(.secondary)
        }
        Image(systemName: "chevron.right")
    }
}
```

### Custom Reminder Times
```swift
// Morning person
await notificationManager.updateReminderTime(hour: 7, minute: 0)

// Night owl
await notificationManager.updateReminderTime(hour: 21, minute: 30)

// Multiple times
await notificationManager.scheduleMultipleReminders(times: [
    (hour: 8, minute: 0),   // Morning
    (hour: 12, minute: 0),  // Lunch
    (hour: 19, minute: 0)   // Evening
])
```

### Weekend-Specific Logic
```swift
// You could add weekend customization
let calendar = Calendar.current
let isWeekend = calendar.isDateInWeekend(Date())

if isWeekend && !prefs.enableWeekendReminders {
    print("⏸️ Weekend reminders disabled")
    return
}
```

### Streak Milestones
```swift
// Special notifications for milestones
if streakCount == 7 {
    content.title = "First Week Complete! 🎉"
    content.body = "You've built a habit! Keep going strong"
} else if streakCount == 30 {
    content.title = "30 Days of Faith! 🏆"
    content.body = "You're amazing! This is a life-changing habit"
}
```

## 📱 Testing Your Customizations

### 1. Test Lesson Completion
```
1. Start a lesson
2. Complete all slides
3. Check console: "✅ Lesson completed - clearing badge"
4. Verify badge disappears
```

### 2. Test Streak Notifications
```
1. Build up a 7+ day streak
2. Wait for notification time
3. Should see streak-specific message
```

### 3. Test Multiple Reminders
```swift
// Add this to test multiple times
await notificationManager.scheduleMultipleReminders(times: [
    (hour: Calendar.current.component(.hour, from: Date()), 
     minute: Calendar.current.component(.minute, from: Date()) + 1),
    (hour: Calendar.current.component(.hour, from: Date()), 
     minute: Calendar.current.component(.minute, from: Date()) + 2)
])
```

## 🎯 Key Benefits

1. **Smart Detection** - No unnecessary notifications
2. **Streak Motivation** - Personalized messaging for engaged users
3. **Flexible Timing** - Multiple reminder options
4. **User Control** - Comprehensive preference system
5. **Automatic Cleanup** - Badges clear when appropriate

## 🚀 Ready to Use!

The smart notification system is now complete! Users will:
- Get personalized reminders based on their engagement
- See streak-specific motivation
- Have badges automatically managed
- Never get redundant notifications for completed lessons

Build and test it now! 🙏✨
