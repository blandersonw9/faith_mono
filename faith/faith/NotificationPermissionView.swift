//
//  NotificationPermissionView.swift
//  faith
//
//  View to request notification permissions from users
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) var dismiss
    @State private var isRequesting = false
    
    var onComplete: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(StyleGuide.mainBrown.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            .padding(.bottom, 32)
            
            // Title
            Text("Stay Connected")
                .font(StyleGuide.merriweather(size: 28, weight: .bold))
                .foregroundColor(StyleGuide.mainBrown)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            // Description
            Text("Get a gentle daily reminder to continue your faith journey. We'll send one notification each day at a time you choose.")
                .font(StyleGuide.merriweather(size: 16))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            
            // Benefits list
            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(icon: "calendar", text: "Daily reminders at your preferred time")
                BenefitRow(icon: "moon.stars", text: "Never miss your daily lesson")
                BenefitRow(icon: "heart.fill", text: "Build a consistent faith practice")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    requestPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enable Notifications")
                                .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(StyleGuide.mainBrown)
                    .cornerRadius(16)
                }
                .disabled(isRequesting)
                
                Button(action: {
                    skipForNow()
                }) {
                    Text("Maybe Later")
                        .font(StyleGuide.merriweather(size: 16))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                }
                .frame(height: 44)
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
            .padding(.bottom, StyleGuide.spacing.xl)
        }
        .background(StyleGuide.backgroundBeige)
    }
    
    private func requestPermission() {
        isRequesting = true
        Task {
            let granted = await notificationManager.requestAuthorization()
            isRequesting = false
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
            
            // Call completion handler and dismiss
            onComplete?()
            dismiss()
        }
    }
    
    private func skipForNow() {
        onComplete?()
        dismiss()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(StyleGuide.mainBrown)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(StyleGuide.merriweather(size: 16))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
            
            Spacer()
        }
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(NotificationManager())
}

