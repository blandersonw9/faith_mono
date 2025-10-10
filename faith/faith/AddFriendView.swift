//
//  AddFriendView.swift
//  faith
//
//  View for adding new friends by username
//

import SwiftUI
import MessageUI

struct AddFriendView: View {
    @ObservedObject var userDataManager: UserDataManager
    
    @State private var username: String = ""
    @State private var isSendingRequest = false
    @State private var showingSuccessMessage = false
    @State private var showingErrorMessage = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var showingMessageComposer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: StyleGuide.spacing.xl) {
                topSpacing
                headerSection
                inputCardSection
                statusMessagesSection
                inviteSection
                tipsSection
                bottomSpacing
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposeView(
                message: createInviteMessage(),
                onDismiss: {
                    showingMessageComposer = false
                }
            )
        }
        .onAppear {
            // Check for pending friend username from deep link
            if let pendingUsername = UserDefaults.standard.string(forKey: "pendingFriendUsername") {
                username = pendingUsername
                UserDefaults.standard.removeObject(forKey: "pendingFriendUsername")
            }
        }
    }
    
    // MARK: - View Components
    
    private var topSpacing: some View {
        Spacer()
            .frame(height: 40)
    }
    
    private var headerSection: some View {
        VStack(spacing: StyleGuide.spacing.md) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(StyleGuide.gold)
            
            Text("Add a Friend")
                .font(StyleGuide.merriweather(size: 24, weight: .bold))
                .foregroundColor(StyleGuide.mainBrown)
            
            Text("Send friend invites by entering their username")
                .font(StyleGuide.merriweather(size: 14, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, StyleGuide.spacing.lg)
        }
    }
    
    private var inputCardSection: some View {
        VStack(spacing: StyleGuide.spacing.lg) {
            usernameInputField
            sendRequestButton
        }
        .padding(StyleGuide.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(StyleGuide.gold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .padding(.horizontal, StyleGuide.spacing.lg)
    }
    
    private var usernameInputField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Username")
                .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
            
            usernameTextField
            
            Text("Username must contain only letters, numbers, dots, and underscores")
                .font(StyleGuide.merriweather(size: 12, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                .padding(.leading, 2)
        }
    }
    
    private var usernameTextField: some View {
        HStack(spacing: 12) {
            Text("@")
                .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
            
            TextField("Enter username", text: $username)
                .font(StyleGuide.merriweather(size: 17, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onChange(of: username) { newValue in
                    // Clean the input to only allow valid username characters
                    username = newValue.lowercased()
                        .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
                    
                    // Clear any previous messages when user starts typing
                    if !newValue.isEmpty {
                        showingSuccessMessage = false
                        showingErrorMessage = false
                    }
                }
        }
        .padding(StyleGuide.spacing.md + 2)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(textFieldBorderColor, lineWidth: 1.5)
        )
    }
    
    private var textFieldBorderColor: Color {
        if showingErrorMessage {
            return Color.red.opacity(0.6)
        } else if showingSuccessMessage {
            return Color.green.opacity(0.6)
        } else {
            return StyleGuide.gold.opacity(0.3)
        }
    }
    
    private var sendRequestButton: some View {
        Button(action: {
            Task {
                await sendFriendRequest()
            }
        }) {
            HStack(spacing: 12) {
                if isSendingRequest {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                    
                    Text("Sending Request...")
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Send Friend Request")
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(StyleGuide.gold)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(username.isEmpty || isSendingRequest)
        .opacity((username.isEmpty || isSendingRequest) ? 0.6 : 1.0)
    }
    
    private var statusMessagesSection: some View {
        VStack(spacing: StyleGuide.spacing.md) {
            if showingSuccessMessage {
                StatusMessageView(
                    message: successMessage,
                    type: .success
                )
                .padding(.horizontal, StyleGuide.spacing.lg)
            }
            
            if showingErrorMessage {
                StatusMessageView(
                    message: errorMessage,
                    type: .error
                )
                .padding(.horizontal, StyleGuide.spacing.lg)
            }
        }
    }
    
    private var inviteSection: some View {
        VStack(spacing: StyleGuide.spacing.md) {
            // Divider
            HStack {
                Rectangle()
                    .fill(StyleGuide.mainBrown.opacity(0.2))
                    .frame(height: 1)
                
                Text("OR")
                    .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                    .padding(.horizontal, StyleGuide.spacing.md)
                
                Rectangle()
                    .fill(StyleGuide.mainBrown.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
            
            HStack {
                Text("Invite Someone New")
                    .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                    .textCase(.uppercase)
                
                Spacer()
            }
            
            Button(action: {
                if MFMessageComposeViewController.canSendText() {
                    showingMessageComposer = true
                } else {
                    // Fallback to share sheet
                    shareInvite()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Send Text Invite")
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.7)
                }
                .foregroundColor(.white)
                .padding(.horizontal, StyleGuide.spacing.lg)
                .padding(.vertical, StyleGuide.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text("Invite friends who don't have the app yet")
                .font(StyleGuide.merriweather(size: 12, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, StyleGuide.spacing.lg)
    }
    
    private var tipsSection: some View {
        VStack(spacing: StyleGuide.spacing.md) {
            HStack {
                Text("Tips")
                    .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                    .textCase(.uppercase)
                
                Spacer()
            }
            
            VStack(spacing: StyleGuide.spacing.sm) {
                TipRowView(
                    icon: "lightbulb.fill",
                    text: "Ask your friend for their exact username"
                )
                
                TipRowView(
                    icon: "person.2.fill",
                    text: "They'll receive a notification about your request"
                )
                
                TipRowView(
                    icon: "checkmark.circle.fill",
                    text: "Once accepted, you'll both be friends"
                )
            }
        }
        .padding(.horizontal, StyleGuide.spacing.lg)
    }
    
    private var bottomSpacing: some View {
        Spacer()
            .frame(height: 100)
    }
    
    @MainActor
    private func sendFriendRequest() async {
        guard !username.isEmpty else { return }
        
        isSendingRequest = true
        showingSuccessMessage = false
        showingErrorMessage = false
        
        do {
            try await userDataManager.sendFriendRequest(to: username)
            
            // Success
            successMessage = "Friend request sent to @\(username)!"
            showingSuccessMessage = true
            username = "" // Clear the input
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Auto-hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showingSuccessMessage = false
                }
            }
            
        } catch {
            // Error
            if let nsError = error as NSError? {
                errorMessage = nsError.localizedDescription
            } else {
                errorMessage = "Failed to send friend request. Please try again."
            }
            showingErrorMessage = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // Auto-hide error message after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showingErrorMessage = false
                }
            }
        }
        
        isSendingRequest = false
    }
    
    // MARK: - Invite Functions
    
    private func shareInvite() {
        let inviteMessage = createInviteMessage()
        
        let activityViewController = UIActivityViewController(
            activityItems: [inviteMessage],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func createInviteMessage() -> String {
        let userName = userDataManager.getDisplayName()
        let appStoreLink = "https://apps.apple.com/app/faith-daily-devotions/id6736678479" // Replace with actual App Store link
        let friendLink = "faithapp://addfriend?username=\(userName)"
        
        return """
        Hey! 🙏 I've been growing in my faith with this amazing app called Faith and wanted to invite you to join me!
        
        It has:
        • Daily devotions & Bible reading
        • Streak tracking to stay consistent  
        • We can be friends and encourage each other!
        
        Download Faith: \(appStoreLink)
        
        Then tap this link to add me as a friend: \(friendLink)
        
        Or manually add me with username: @\(userName)
        
        Would love to share this faith journey with you! ✨
        """
    }
}

// MARK: - Status Message View

struct StatusMessageView: View {
    let message: String
    let type: MessageType
    
    enum MessageType {
        case success
        case error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
            
            Text(message)
                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                .foregroundColor(type.color.opacity(0.9))
            
            Spacer()
        }
        .padding(StyleGuide.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(type.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tip Row View

struct TipRowView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: StyleGuide.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(StyleGuide.gold)
                .frame(width: 20)
            
            Text(text)
                .font(StyleGuide.merriweather(size: 13, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, StyleGuide.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(StyleGuide.gold.opacity(0.08))
        )
    }
}

// MARK: - Message Compose View

struct MessageComposeView: UIViewControllerRepresentable {
    let message: String
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = message
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            onDismiss()
        }
    }
}

#Preview {
    AddFriendView(userDataManager: UserDataManager(supabase: AuthManager().supabase, authManager: AuthManager()))
}
