
import SwiftUI
import Supabase

// MARK: - Chat View
struct ChatView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingChat: Bool
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatMessageView(message: message)
                    }
                }
                .padding(.horizontal, StyleGuide.spacing.lg)
                .padding(.vertical, StyleGuide.spacing.md)
            }
            .background(StyleGuide.backgroundBeige)
            
            // Message Input
            ChatInputView(messageText: $messageText, isLoading: isLoading) {
                sendMessage()
            }
        }
        .navigationTitle("Faith Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    showingChat = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        
        let userMessage = ChatMessage(content: messageText, isUser: true)
        messages.append(userMessage)
        let currentMessage = messageText
        messageText = ""
        isLoading = true
        
        Task {
            do {
                let response = try await sendToAPI(message: currentMessage)
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(content: "I apologize, but I'm having trouble responding right now. Please try again later.", isUser: false)
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    private func sendToAPI(message: String) async throws -> String {
        let session = try await authManager.supabase.auth.session
        
        // Convert messages to OpenAI format
        let openAIMessages = messages.map { msg in
            ["role": msg.isUser ? "user" : "assistant", "content": msg.content]
        } + [["role": "user", "content": message]]
        
        let requestBody: [String: Any] = [
            "messages": openAIMessages
        ]
        
        guard let url = URL(string: "https://ppkqyfcnwajfzhvnqxec.supabase.co/functions/v1/bright-processor") else {
            throw ChatError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw ChatError.rateLimited
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatError.invalidResponse
        }
        
        return content
    }
}

enum ChatError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case rateLimited
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited:
            return "Rate limit exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            if !message.isUser {
                Text("Faith:")
                    .font(StyleGuide.merriweather(size: 12, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                if message.isUser {
                    Spacer()
                }
                
                Text(message.content)
                    .font(StyleGuide.merriweather(size: 16))
                    .foregroundColor(message.isUser ? StyleGuide.mainBrown : StyleGuide.mainBrown)
                    .padding(.horizontal, message.isUser ? 16 : 0)
                    .padding(.vertical, message.isUser ? 12 : 8)
                    .background(
                        message.isUser ? StyleGuide.backgroundBeige : Color.clear
                    )
                    .overlay(
                        message.isUser ? 
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(StyleGuide.mainBrown.opacity(0.25), lineWidth: 1) : 
                        nil
                    )
                    .cornerRadius(message.isUser ? 20 : 0)
                    .shadow(color: message.isUser ? StyleGuide.shadows.sm : Color.clear, radius: 2, x: 0, y: 1)
                
                if !message.isUser {
                    Spacer()
                }
            }
        }
    }
}

struct ChatInputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $messageText)
                .font(StyleGuide.merriweather(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
            
            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .frame(width: 44, height: 44)
                        .background(StyleGuide.mainBrown)
                        .cornerRadius(22)
                        .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(StyleGuide.mainBrown)
                        .cornerRadius(22)
                        .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .opacity((messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading) ? 0.5 : 1.0)
        }
        .padding(.horizontal, StyleGuide.spacing.lg)
        .padding(.vertical, StyleGuide.spacing.md)
        .background(Color.white)
    }
}