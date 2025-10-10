//
//  FriendRequestsView.swift
//  faith
//
//  View for managing incoming friend requests
//

import SwiftUI

struct FriendRequestsView: View {
    @ObservedObject var userDataManager: UserDataManager
    @State private var processingRequest: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: StyleGuide.spacing.lg) {
                // Top spacing
                Spacer()
                    .frame(height: 20)
                
                if userDataManager.friendRequests.isEmpty {
                    // Empty state
                    VStack(spacing: StyleGuide.spacing.lg) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                        
                        VStack(spacing: StyleGuide.spacing.sm) {
                            Text("No friend requests")
                                .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown)
                            
                            Text("When someone sends you a friend request, it will appear here")
                                .font(StyleGuide.merriweather(size: 14, weight: .regular))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, StyleGuide.spacing.xl)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Friend requests list
                    LazyVStack(spacing: StyleGuide.spacing.md) {
                        ForEach(userDataManager.friendRequests) { request in
                            FriendRequestRowView(
                                request: request,
                                isProcessing: processingRequest == request.requester_username,
                                onAccept: {
                                    Task {
                                        await acceptRequest(request)
                                    }
                                },
                                onDecline: {
                                    Task {
                                        await declineRequest(request)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, StyleGuide.spacing.lg)
                }
                
                // Bottom spacing
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    @MainActor
    private func acceptRequest(_ request: FriendRequest) async {
        processingRequest = request.requester_username
        
        do {
            try await userDataManager.acceptFriendRequest(from: request.requester_username)
            
            // Haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            print("❌ Error accepting friend request: \(error)")
            
            // Haptic feedback for error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        processingRequest = nil
    }
    
    @MainActor
    private func declineRequest(_ request: FriendRequest) async {
        processingRequest = request.requester_username
        
        do {
            try await userDataManager.declineFriendRequest(from: request.requester_username)
            
            // Haptic feedback for success
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        } catch {
            print("❌ Error declining friend request: \(error)")
            
            // Haptic feedback for error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        processingRequest = nil
    }
}

// MARK: - Friend Request Row View

struct FriendRequestRowView: View {
    let request: FriendRequest
    let isProcessing: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: StyleGuide.spacing.md) {
            // Header with user info
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
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.requester_display_name)
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text("@\(request.requester_username)")
                        .font(StyleGuide.merriweather(size: 13, weight: .regular))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                    
                    Text(request.relativeDate)
                        .font(StyleGuide.merriweather(size: 11, weight: .regular))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: StyleGuide.spacing.md) {
                // Decline button
                Button(action: onDecline) {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: StyleGuide.mainBrown.opacity(0.6)))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text("Decline")
                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                    }
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(StyleGuide.mainBrown.opacity(0.2), lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
                
                // Accept button
                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text("Accept")
                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(StyleGuide.gold)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
            }
        }
        .padding(StyleGuide.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(StyleGuide.gold.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    FriendRequestsView(userDataManager: UserDataManager(supabase: AuthManager().supabase, authManager: AuthManager()))
}
