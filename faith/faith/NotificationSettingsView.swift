//
//  NotificationSettingsView.swift
//  faith
//
//  View for managing notification settings (can be added to ProfileView later)
//

import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var notificationsEnabled: Bool = false
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var showingTimePicker = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                        .tint(StyleGuide.mainBrown)
                        .onChange(of: notificationsEnabled) { newValue in
                            handleToggleChange(newValue)
                        }
                } header: {
                    Text("Notifications")
                }
                
                if notificationsEnabled {
                    Section {
                        HStack {
                            Text("Reminder Time")
                                .foregroundColor(StyleGuide.mainBrown)
                            
                            Spacer()
                            
                            Button(action: {
                                showingTimePicker = true
                            }) {
                                Text(timeString)
                                    .foregroundColor(StyleGuide.mainBrown)
                            }
                        }
                    } header: {
                        Text("Schedule")
                    } footer: {
                        Text("You'll receive a daily reminder at this time to complete your lesson")
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                    }
                }
                
                Section {
                    Button("Test Notification") {
                        Task {
                            await notificationManager.scheduleDailyReminder()
                            #if DEBUG
                            print("📱 Test notification scheduled")
                            #endif
                        }
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                } footer: {
                    Text("In debug mode, you'll receive a test notification 10 seconds after tapping this button")
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                TimePickerSheet(
                    hour: $selectedHour,
                    minute: $selectedMinute,
                    onSave: {
                        saveTimeChange()
                    }
                )
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var timeString: String {
        let hour12 = selectedHour == 0 ? 12 : (selectedHour > 12 ? selectedHour - 12 : selectedHour)
        let period = selectedHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, selectedMinute, period)
    }
    
    private func loadCurrentSettings() {
        notificationsEnabled = notificationManager.isAuthorized
        let (hour, minute) = notificationManager.getReminderTime()
        selectedHour = hour
        selectedMinute = minute
    }
    
    private func handleToggleChange(_ enabled: Bool) {
        if enabled {
            // Request permission if not already authorized
            if !notificationManager.isAuthorized {
                Task {
                    let granted = await notificationManager.requestAuthorization()
                    if !granted {
                        // User denied, turn toggle back off
                        notificationsEnabled = false
                    }
                }
            }
        } else {
            // Cancel notifications
            notificationManager.cancelDailyReminder()
        }
    }
    
    private func saveTimeChange() {
        Task {
            await notificationManager.updateReminderTime(hour: selectedHour, minute: selectedMinute)
        }
    }
}

struct TimePickerSheet: View {
    @Binding var hour: Int
    @Binding var minute: Int
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = hour
                            components.minute = minute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            hour = components.hour ?? 9
                            minute = components.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(NotificationManager())
}

