//
//  ProfileView.swift
//  faith
//
//  Profile view displaying user information and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var userDataManager: UserDataManager
    @State private var showCopiedFeedback = false
    
    var body: some View {
        ZStack {
            // Background
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: StyleGuide.spacing.xl) {
                    // Top spacing
                    Spacer()
                        .frame(height: 20)
                    
                    // Profile Header
                    VStack(spacing: StyleGuide.spacing.md) {
                        // Profile Icon
                        ZStack {
                            Circle()
                                .fill(StyleGuide.gold.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(StyleGuide.gold)
                        }
                        
                        // User Name with Copy Button
                        Button(action: {
                            let username = userDataManager.getDisplayName()
                            UIPasteboard.general.string = username
                            
                            // Show feedback
                            withAnimation {
                                showCopiedFeedback = true
                            }
                            
                            // Hide after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedFeedback = false
                                }
                            }
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            HStack(spacing: 8) {
                                Text(userDataManager.getDisplayName())
                                    .font(StyleGuide.merriweather(size: 28, weight: .bold))
                                    .foregroundColor(StyleGuide.mainBrown)
                                
                                Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(showCopiedFeedback ? .green : StyleGuide.mainBrown.opacity(0.5))
                                    .offset(y: -6)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // User Stats
                        HStack(spacing: StyleGuide.spacing.xl) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image("streak")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(userDataManager.getCurrentStreak())")
                                        .font(StyleGuide.merriweather(size: 24, weight: .bold))
                                        .foregroundColor(StyleGuide.gold)
                                }
                                
                                Text("Day Streak")
                                    .font(StyleGuide.merriweather(size: 12, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            }
                            
                            Rectangle()
                                .fill(StyleGuide.mainBrown.opacity(0.2))
                                .frame(width: 1, height: 40)
                            
                            VStack(spacing: 4) {
                                Text("\(userDataManager.userProgress?.total_xp ?? 0)")
                                    .font(StyleGuide.merriweather(size: 24, weight: .bold))
                                    .foregroundColor(StyleGuide.mainBrown)
                                
                                Text("Total XP")
                                    .font(StyleGuide.merriweather(size: 12, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            }
                        }
                    }
                    .padding(.vertical, StyleGuide.spacing.xl)
                    .padding(.horizontal, StyleGuide.spacing.lg)
                    .background(StyleGuide.backgroundBeige)
                    .cornerRadius(16)
                    .shadow(color: StyleGuide.shadows.md, radius: 8, x: 0, y: 4)
                    .padding(.horizontal, StyleGuide.spacing.lg)
                    
                    // Badges Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        HStack {
                            Text("Badges")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Spacer()
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        // Badge Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            // Example badges
                            BadgeItem(icon: "star.fill", title: "First Step", color: StyleGuide.gold, isEarned: true)
                            BadgeItem(icon: "flame.fill", title: "7 Day", color: .orange, isEarned: false)
                            BadgeItem(icon: "book.fill", title: "Scholar", color: .blue, isEarned: false)
                            BadgeItem(icon: "heart.fill", title: "Devoted", color: .red, isEarned: false)
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                    
                    // Friends Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        Text("Friends")
                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        VStack(spacing: 0) {
                            // Manage Friends Button
                            Button(action: {
                                // TODO: Navigate to friends management
                            }) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    
                                    Text("Manage Friends")
                                        .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                                }
                                .padding(.horizontal, StyleGuide.spacing.lg)
                                .padding(.vertical, StyleGuide.spacing.md)
                                .background(StyleGuide.backgroundBeige)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .cornerRadius(12)
                        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
                        .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                    
                    // Account Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        Text("Account")
                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        VStack(spacing: 0) {
                            // Sign Out Button
                            Button(action: {
                                Task {
                                    await authManager.signOut()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    
                                    Text("Sign Out")
                                        .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                                }
                                .padding(.horizontal, StyleGuide.spacing.lg)
                                .padding(.vertical, StyleGuide.spacing.md)
                                .background(StyleGuide.backgroundBeige)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .cornerRadius(12)
                        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
                        .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
        }
    }
}

// MARK: - Badge Item
struct BadgeItem: View {
    let icon: String
    let title: String
    let color: Color
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned ? color.opacity(0.15) : StyleGuide.mainBrown.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isEarned ? color : StyleGuide.mainBrown.opacity(0.3))
            }
            
            Text(title)
                .font(StyleGuide.merriweather(size: 10, weight: .medium))
                .foregroundColor(isEarned ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .opacity(isEarned ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        ProfileView(userDataManager: UserDataManager(supabase: AuthManager().supabase, authManager: AuthManager()))
            .environmentObject(AuthManager())
    }
}

