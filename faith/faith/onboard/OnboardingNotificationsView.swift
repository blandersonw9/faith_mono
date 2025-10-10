//
//  OnboardingNotificationsView.swift
//  faith
//
//  Onboarding screen for notification permissions
//

import SwiftUI

struct OnboardingNotificationsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isRequesting = false
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 100, height: 100)
                        .shadow(color: StyleGuide.shadows.md, radius: 8, x: 0, y: 3)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 42))
                        .foregroundColor(StyleGuide.mainBrown)
                }
                .padding(.bottom, 32)
                .padding(.top, 20)
                
                // Title
                Text("Stay Connected")
                    .font(StyleGuide.merriweather(size: 28, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                
                // Description
                Text("Get a gentle daily reminder to continue your faith journey")
                    .font(StyleGuide.merriweather(size: 16))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                
                // Benefits cards
                VStack(spacing: 16) {
                    BenefitCard(
                        icon: "calendar",
                        title: "Daily Reminders",
                        description: "Choose your preferred time"
                    )
                    
                    BenefitCard(
                        icon: "heart.fill",
                        title: "Build Consistency",
                        description: "Grow your faith practice"
                    )
                    
                    BenefitCard(
                        icon: "moon.stars",
                        title: "Never Miss a Day",
                        description: "Stay on track with your journey"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                
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
                        .shadow(color: StyleGuide.shadows.md, radius: 8, x: 0, y: 4)
                    }
                    .disabled(isRequesting)
                    
                    Button(action: {
                        skipForNow()
                    }) {
                        Text("Maybe Later")
                            .font(StyleGuide.merriweather(size: 16))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                    }
                    .frame(height: 44)
                }
                .padding(.horizontal, StyleGuide.spacing.lg)
                .padding(.bottom, StyleGuide.spacing.xl)
            }
        }
    }
    
    private func requestPermission() {
        isRequesting = true
        Task {
            let granted = await notificationManager.requestAuthorization()
            isRequesting = false
            
            if granted {
                print("✅ Notification permission granted during onboarding")
            } else {
                print("⚠️ Notification permission denied during onboarding")
            }
            
            // Continue to next step regardless of permission result
            onContinue()
        }
    }
    
    private func skipForNow() {
        print("ℹ️ User skipped notification permission")
        onContinue()
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(StyleGuide.mainBrown.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(StyleGuide.merriweather(size: 17, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text(description)
                    .font(StyleGuide.merriweather(size: 14))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    OnboardingNotificationsView(onContinue: {})
        .environmentObject(NotificationManager())
}

