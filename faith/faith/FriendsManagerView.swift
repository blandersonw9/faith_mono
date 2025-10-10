//
//  FriendsManagerView.swift
//  faith
//
//  Friends management interface with tabs for current friends, requests, and adding new friends
//

import SwiftUI

struct FriendsManagerView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Image("background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea(.all)
                    
                    VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        // Done Button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Done")
                                    .font(StyleGuide.merriweather(size: 16, weight: .medium))
                            }
                            .foregroundColor(StyleGuide.mainBrown)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                            )
                        }
                        
                        Spacer()
                        
                        // Title
                        Text("Friends")
                            .font(StyleGuide.merriweather(size: 20, weight: .bold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        Spacer()
                        
                        // Refresh Button
                        Button(action: {
                            Task {
                                await refreshData()
                            }
                        }) {
                            Group {
                                if isRefreshing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: StyleGuide.mainBrown))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .foregroundColor(StyleGuide.mainBrown)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                            )
                        }
                        .disabled(isRefreshing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    .padding(.bottom, 16)
                    
                    // Custom Tab Bar
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { index in
                            Button(action: {
                                selectedTab = index
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                VStack(spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: tabIcon(for: index))
                                            .font(.system(size: 15, weight: .medium))
                                        
                                        Text(tabTitle(for: index))
                                            .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                                        
                                        // Badge for friend requests
                                        if index == 1 && !userDataManager.friendRequests.isEmpty {
                                            Text("\(userDataManager.friendRequests.count)")
                                                .font(StyleGuide.merriweather(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Circle().fill(.red))
                                        }
                                    }
                                    .foregroundColor(selectedTab == index ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.6))
                                    
                                    // Active indicator
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(selectedTab == index ? StyleGuide.gold : Color.clear)
                                        .frame(height: 3)
                                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTab == index ? StyleGuide.gold.opacity(0.1) : Color.clear)
                                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        // Current Friends Tab
                        FriendsListView(userDataManager: userDataManager)
                            .tag(0)
                        
                        // Friend Requests Tab
                        FriendRequestsView(userDataManager: userDataManager)
                            .tag(1)
                        
                        // Add Friends Tab
                        AddFriendView(userDataManager: userDataManager)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await refreshData()
                
                // If opened via deep link or user has no friends and no pending requests, start on the "Add Friend" tab for better UX
                if UserDefaults.standard.string(forKey: "pendingFriendUsername") != nil || 
                   (userDataManager.friends.isEmpty && userDataManager.friendRequests.isEmpty) {
                    selectedTab = 2
                }
            }
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "person.2.fill"
        case 1: return "person.badge.plus"
        case 2: return "person.badge.plus.fill"
        default: return "person.fill"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Friends"
        case 1: return "Requests"
        case 2: return "Add Friend"
        default: return ""
        }
    }
    
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        
        do {
            async let friendsTask = userDataManager.fetchFriends()
            async let requestsTask = userDataManager.fetchFriendRequests()
            
            try await friendsTask
            try await requestsTask
        } catch {
            print("❌ Error refreshing friends data: \(error)")
        }
        
        isRefreshing = false
    }
}

// MARK: - Friends List View

struct FriendsListView: View {
    @ObservedObject var userDataManager: UserDataManager
    @State private var showingRemoveAlert = false
    @State private var friendToRemove: Friend?
    
    var body: some View {
        ScrollView {
            VStack(spacing: StyleGuide.spacing.lg) {
                // Top spacing
                Spacer()
                    .frame(height: 20)
                
                if userDataManager.friends.isEmpty {
                    // Empty state
                    VStack(spacing: StyleGuide.spacing.lg) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: "person.2")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                        
                        VStack(spacing: StyleGuide.spacing.sm) {
                            Text("No friends yet")
                                .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown)
                            
                            Text("Add friends to share your faith journey together")
                                .font(StyleGuide.merriweather(size: 14, weight: .regular))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, StyleGuide.spacing.xl)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Friends list
                    LazyVStack(spacing: StyleGuide.spacing.md) {
                        ForEach(userDataManager.friends) { friend in
                            FriendRowView(friend: friend) {
                                friendToRemove = friend
                                showingRemoveAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, StyleGuide.spacing.lg)
                }
                
                // Bottom spacing
                Spacer()
                    .frame(height: 100)
            }
        }
        .alert("Remove Friend", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let friend = friendToRemove {
                    Task {
                        do {
                            try await userDataManager.removeFriend(username: friend.username)
                        } catch {
                            print("❌ Error removing friend: \(error)")
                        }
                    }
                }
            }
        } message: {
            if let friend = friendToRemove {
                Text("Are you sure you want to remove \(friend.display_name) from your friends?")
            }
        }
    }
}

// MARK: - Friend Row View

struct FriendRowView: View {
    let friend: Friend
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: StyleGuide.spacing.md) {
            // Profile picture placeholder
            ZStack {
                Circle()
                    .fill(StyleGuide.gold.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(StyleGuide.gold)
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.display_name)
                    .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text("@\(friend.username)")
                    .font(StyleGuide.merriweather(size: 13, weight: .regular))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                
                Text("Friends since \(friend.formattedDate)")
                    .font(StyleGuide.merriweather(size: 11, weight: .regular))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
            }
            
            Spacer()
            
            // More options button
            Menu {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                    .padding(8)
            }
        }
        .padding(StyleGuide.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(StyleGuide.mainBrown.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        FriendsManagerView(userDataManager: UserDataManager(supabase: AuthManager().supabase, authManager: AuthManager()))
    }
}
