import SwiftUI
import Supabase

// MARK: - Chat View
struct ChatView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingChat: Bool
    @State private var messages: [ChatMessage] = [
        .init(id: UUID(), role: .system, text: "How can I help you with your faith journey today?")
    ]
    @State private var inputText: String = ""
    @State private var isLoading = false
    @GestureState private var dragTranslation: CGSize = .zero
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with chevron left
            HStack(spacing: 12) {
                Button(action: { 
                    showingChat = false 
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                }
                .buttonStyle(.plain)
                
                Text("Faith Chat")
                    .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(StyleGuide.mainBrown.opacity(0.1))
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(messages) { message in
                            if message.role == .assistant || message.role == .system {
                                AssistantBlock(text: message.text)
                                    .padding(.horizontal, 16)
                                    .id(message.id)
                            } else {
                                HStack {
                                    Spacer(minLength: 40)
                                    UserBubble(text: message.text)
                                }
                                .padding(.horizontal, 16)
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _ in
                    if let last = messages.last?.id {
                        withAnimation(.easeInOut(duration: 0.25)) { 
                            proxy.scrollTo(last, anchor: .bottom) 
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            
            // Input bar
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    TextField("Send a message", text: $inputText, axis: .vertical)
                        .font(StyleGuide.merriweather(size: 16))
                        .lineLimit(4)
                        .focused($isInputFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: { sendMessage() }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(StyleGuide.mainBrown)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(StyleGuide.mainBrown.opacity(0.12), lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture { isInputFocused = true }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let dy = value.translation.height
                            if dy > 50 { // swipe down on input to dismiss keyboard
                                isInputFocused = false
                            }
                        }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.clear)
        }
        .background(StyleGuide.backgroundBeige.ignoresSafeArea())
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let dy = value.translation.height
                    let dx = value.translation.width
                    // Only dismiss if it's a significant downward swipe and not too horizontal
                    if dy > 150 && abs(dx) < 50 {
                        showingChat = false
                    }
                }
        )
        .onAppear {
            // Raise keyboard shortly after appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isInputFocused = true
            }
        }
    }
    
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isLoading else { return }
        
        // Clear input immediately
        inputText = ""
        isInputFocused = true
        
        // Add user message
        messages.append(.init(id: UUID(), role: .user, text: trimmed))
        isLoading = true
        
        Task {
            do {
                let response = try await sendToAPI(message: trimmed)
                await MainActor.run {
                    messages.append(.init(id: UUID(), role: .assistant, text: response))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(.init(id: UUID(), role: .assistant, text: "I apologize, but I'm having trouble responding right now. Please try again later."))
                    isLoading = false
                }
            }
        }
    }
    
    private func sendToAPI(message: String) async throws -> String {
        let session = try await authManager.supabase.auth.session
        
        // Convert messages to OpenAI format
        let openAIMessages = messages.map { msg in
            ["role": msg.role == .user ? "user" : msg.role == .assistant ? "assistant" : "system", "content": msg.text]
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

// MARK: - Message Components
struct AssistantBlock: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Faith:")
                .font(StyleGuide.merriweather(size: 16))
                .foregroundStyle(StyleGuide.mainBrown.opacity(0.5))
            BasicMarkdownText(text: text)
                .foregroundStyle(StyleGuide.mainBrown)
        }
    }
}

struct UserBubble: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BasicMarkdownText(text: text)
                .foregroundStyle(StyleGuide.mainBrown)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(StyleGuide.mainBrown.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Basic Markdown Support
private struct BasicMarkdownText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(lines(), id: \.self) { line in
                if let header = parseHeader(line) {
                    Text(header.content)
                        .font(StyleGuide.merriweather(size: header.size, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                } else if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("")
                        .font(StyleGuide.merriweather(size: 6))
                        .padding(.vertical, 2)
                } else {
                    boldSpans(for: line)
                }
            }
        }
    }

    private func lines() -> [String] {
        text.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    private func parseHeader(_ line: String) -> (level: Int, content: String, size: CGFloat)? {
        if line.hasPrefix("### ") { return (3, String(line.dropFirst(4)), 18) }
        if line.hasPrefix("## ") { return (2, String(line.dropFirst(3)), 20) }
        if line.hasPrefix("# ") { return (1, String(line.dropFirst(2)), 22) }
        return nil
    }

    @ViewBuilder
    private func boldSpans(for line: String) -> some View {
        let parts = splitBoldItalic(line)
        let base = StyleGuide.merriweather(size: 16)
        parts.enumerated().reduce(Text("") as Text) { acc, pair in
            let (idx, part) = pair
            var t = Text(part.text)
                .font(base.weight(part.isBold ? .bold : .regular))
            if part.isItalic { t = t.italic() }
            return idx == 0 ? t : acc + t
        }
        .multilineTextAlignment(.leading)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
    }

    private struct Span { let text: String; let isBold: Bool; let isItalic: Bool }

    private func splitBoldItalic(_ input: String) -> [Span] {
        var spans: [Span] = []
        var i = input.startIndex
        var buffer = ""
        func flush() { if !buffer.isEmpty { spans.append(Span(text: buffer, isBold: false, isItalic: false)); buffer = "" } }
        while i < input.endIndex {
            if input[i...].hasPrefix("**"), let close = input[input.index(i, offsetBy: 2)...].range(of: "**") {
                flush()
                let content = String(input[input.index(i, offsetBy: 2)..<close.lowerBound])
                spans.append(Span(text: content, isBold: true, isItalic: false))
                i = input.index(close.lowerBound, offsetBy: 2)
                continue
            }
            if input[i] == "*" {
                let after = input.index(after: i)
                if after < input.endIndex, let close = input[after...].firstIndex(of: "*") {
                    flush()
                    let content = String(input[after..<close])
                    spans.append(Span(text: content, isBold: false, isItalic: true))
                    i = input.index(after: close)
                    continue
                }
            }
            buffer.append(input[i])
            i = input.index(after: i)
        }
        flush()
        return spans
    }
}

// MARK: - Data Models
struct ChatMessage: Identifiable {
    enum Role { case system, user, assistant }
    let id: UUID
    let role: Role
    let text: String
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