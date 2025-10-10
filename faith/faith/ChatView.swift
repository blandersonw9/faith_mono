import SwiftUI
import UIKit
import Supabase
import Combine

// MARK: - Chat View
/// Conversational UI for Faith chat. Handles message list, input, suggestions,
/// and navigation links embedded in assistant text.
struct ChatView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var bibleNavigator: BibleNavigator
    @Binding var showingChat: Bool
    @Binding var selectedTab: Int
    var initialPrompt: String? = nil
    @State private var messages: [ChatMessage] = [
        .init(id: UUID(), role: .system, text: "What's on your mind?")
    ]
    @State private var inputText: String = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool
    @State private var suggestions: [String] = []
    @State private var isFetchingSuggestions = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingHistory: Bool = false
    @State private var currentConversationId: UUID? = nil
    @State private var typingAssistantId: UUID? = nil
    
    // UI constants to avoid magic numbers
    private enum UI {
        static let bottomFadeThreshold: CGFloat = -30
        static let bottomFadeHeight: CGFloat = 24
    }
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // Get current reading mode for proper background
    private var currentReadingMode: ReadingMode {
        if let saved = UserDefaults.standard.string(forKey: "bibleReadingMode"),
           let mode = ReadingMode(rawValue: saved) {
            return mode
        }
        return .day
    }
    
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
                        .frame(width: 32, height: 44) // Larger tap target
                        .contentShape(Rectangle()) // Make entire frame tappable
                }
                .buttonStyle(BackButtonStyle())
                
                Text("Faith Chat")
                    .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Spacer()
                Button(action: { showingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                        .frame(width: 44, height: 44) // Larger tap target
                        .contentShape(Rectangle()) // Make entire frame tappable
                }
                .buttonStyle(BackButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(StyleGuide.mainBrown.opacity(0.1))
            
            // Messages list
            ScrollViewReader { proxy in
                GeometryReader { scrollViewGeometry in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 32) {
                            ForEach(messages) { message in
                                MessageRow(
                                    message: message,
                                    isLoading: isLoading,
                                    typingAssistantId: typingAssistantId
                                )
                                .equatable()
                                .id(message.id)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, (!isLoading && !suggestions.isEmpty) ? 20 : 12)
                        .background(
                            GeometryReader { contentGeometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: contentGeometry.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollDismissesKeyboard(.interactively)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        let offset = value - scrollViewGeometry.size.height
                        // Check if content is scrolled up (would be behind suggestions)
                        scrollOffset = offset
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last?.id {
                            let shouldAnimate = messages.count <= 60
                            if shouldAnimate {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    proxy.scrollTo(last, anchor: .bottom)
                                }
                            } else {
                                // Avoid heavy animated layout for long transcripts
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                    // no-op
                }
        // Bottom fade overlay - only visible when content is scrolled behind suggestions
        .overlay(alignment: .bottom) {
            if !isLoading && !suggestions.isEmpty && scrollOffset < UI.bottomFadeThreshold {
                LinearGradient(
                    gradient: Gradient(colors: [
                        StyleGuide.backgroundBeige.opacity(0),
                        StyleGuide.backgroundBeige
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: UI.bottomFadeHeight)
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
            }
            
            // Suggestions row
            if !isLoading && !suggestions.isEmpty {
                SuggestionsRow(suggestions: suggestions) { suggestion in
                    sendMessageFromSuggestion(suggestion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Input bar (soft neuromorphic capsule)
            NeuromorphicInputBar(
                text: $inputText,
                onSubmit: { sendMessage() },
                isFocused: $isInputFocused
            )
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 14)
            .background(Color.clear)
        }
        .background(
            ZStack {
                if isDragging {
                    // Three-panel background system when dragging
                    HStack(spacing: 0) {
                        // Left panel: underlying screen background
                        Group {
                            if selectedTab == 0 {
                                Image("background")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                currentReadingMode.backgroundColor
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width)
                        .ignoresSafeArea(.all)
                        
                        // Center panel: chat background
                        StyleGuide.backgroundBeige
                            .frame(width: UIScreen.main.bounds.width)
                            .ignoresSafeArea(.all)
                        
                        // Right panel: chat background (for negative drags)
                        StyleGuide.backgroundBeige
                            .frame(width: UIScreen.main.bounds.width)
                            .ignoresSafeArea(.all)
                    }
                    .offset(x: -UIScreen.main.bounds.width + dragOffset)
                } else {
                    // Normal chat background when not dragging
                    StyleGuide.backgroundBeige
                        .ignoresSafeArea(.all)
                }
            }
        )
        .offset(x: dragOffset)
        .animation(isDragging ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    // Only respond to swipes starting from the left edge (within 20 points)
                    // but exclude the top bar area where buttons are located
                    guard value.startLocation.x < 20 && value.startLocation.y > 80 else { return }
                    
                    let dx = value.translation.width
                    let dy = abs(value.translation.height)
                    
                    // Start dragging on any significant horizontal motion
                    if abs(dx) > 5 && dy < max(100, abs(dx) * 0.75) {
                        isDragging = true
                    }
                    
                    // Update dragOffset for any movement while dragging, but clamp it
                    if isDragging {
                        dragOffset = max(-100, min(dx, 200)) // Allow small negative drag, cap positive
                    }
                }
                .onEnded { value in
                    guard isDragging else { return }
                    
                    let dx = value.translation.width
                    let velocity = value.velocity.width
                    
                    isDragging = false
                    
                    // Dismiss if dragged far enough OR has sufficient velocity
                    if dx > 80 || (dx > 30 && velocity > 300) {
                        // Dismiss immediately and let SwiftUI handle the transition
                        showingChat = false
                        // Reset drag offset immediately to avoid visual glitches
                        dragOffset = 0
                    } else {
                        // Spring back if not dragged far enough
                        dragOffset = 0
                    }
                }
        )
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "faithbible" {
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   comps.host == "open",
                   let bookStr = comps.queryItems?.first(where: { $0.name == "book" })?.value,
                   let chapStr = comps.queryItems?.first(where: { $0.name == "chapter" })?.value,
                   let book = Int(bookStr), let chapter = Int(chapStr) {
                    let verse = comps.queryItems?.first(where: { $0.name == "verse" })?.value.flatMap { Int($0) }
                    // Persist selection for BibleView listener
                    UserDefaults.standard.set(book, forKey: "savedBibleBook")
                    UserDefaults.standard.set(chapter, forKey: "savedBibleChapter")
                    if let v = verse { UserDefaults.standard.set(v, forKey: "savedBibleVerse") } else { UserDefaults.standard.removeObject(forKey: "savedBibleVerse") }
                    // Notify and switch tab
                    NotificationCenter.default.post(name: .navigateToBibleTab, object: nil)
                    selectedTab = 1
                    showingChat = false
                    return .handled
                }
                return .discarded
            }
            return .systemAction
        })
        
        .sheet(isPresented: $showingHistory) {
            ChatHistoryView(
                store: ChatStore.shared,
                onSelect: { id in loadConversation(id: id) },
                onStartNew: { startNewConversation() }
            )
        }
        
        .onAppear {
            // Raise keyboard shortly after appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isInputFocused = true
            }
            Task { await refreshSuggestions() }
            if let prompt = initialPrompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await sendMessageInternal(messageText: prompt) }
            }
        }
    }
    
    /// Handles send from the input field, trims text and triggers async send.
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isLoading else { return }
        
        // Clear input immediately
        inputText = ""
        isInputFocused = true
        
        Task { await sendMessageInternal(messageText: trimmed) }
    }

    /// Sends a provided suggestion string as the next user message.
    private func sendMessageFromSuggestion(_ suggestion: String) {
        let trimmed = suggestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isLoading else { return }
        isInputFocused = true
        Task { await sendMessageInternal(messageText: trimmed) }
    }

    /// Appends the user's message, shows an assistant placeholder, calls the API,
    /// animates the response, and refreshes follow-up suggestions.
    private func sendMessageInternal(messageText: String) async {
        // Add user message and placeholder, snapshot conversation
        let assistantId = UUID()
        var conversationSnapshot: [ChatMessage] = []
        await MainActor.run {
            let userMessage = ChatMessage(id: UUID(), role: .user, text: messageText)
            messages.append(userMessage)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.90, blendDuration: 0.1)) {
                isLoading = true
            }
            conversationSnapshot = messages
            messages.append(.init(id: assistantId, role: .assistant, text: ""))
            typingAssistantId = assistantId
        }

        do {
            // Non-streaming: fetch full response and type it out client-side
            let response = try await sendToAPI(message: messageText, conversation: conversationSnapshot)
            await animateAssistantText(messageId: assistantId, fullText: response)
            await refreshSuggestions()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.1)) {
                    isLoading = false
                }
                typingAssistantId = nil
            }
            // Persist conversation after assistant responds
            let current = await MainActor.run { messages }
            let convo = await ChatStore.shared.upsertConversation(from: current, existingId: currentConversationId)
            await MainActor.run { currentConversationId = convo.id }
        } catch {
            #if DEBUG
            print("❌ Chat API Error: \(error)")
            print("   Error type: \(type(of: error))")
            if let chatError = error as? ChatError {
                print("   Chat error: \(chatError.errorDescription ?? "unknown")")
            }
            if let urlError = error as? URLError {
                print("   URL error code: \(urlError.code)")
                print("   URL error description: \(urlError.localizedDescription)")
            }
            #endif
            await MainActor.run {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx] = ChatMessage(id: assistantId, role: .assistant, text: "I apologize, but I'm having trouble responding right now. Please try again later.")
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.1)) {
                    isLoading = false
                }
                typingAssistantId = nil
            }
            // Persist partial conversation even on failure
            let current = await MainActor.run { messages }
            let convo = await ChatStore.shared.upsertConversation(from: current, existingId: currentConversationId)
            await MainActor.run { currentConversationId = convo.id }
        }
    }

    private func loadConversation(id: UUID) {
        Task {
            // Avoid animating a large list rebuild
            await MainActor.run { withAnimation(nil) { } }
            if let loaded = await ChatStore.shared.loadConversation(id: id) {
                await MainActor.run {
                    currentConversationId = id
                    messages = loaded
                    inputText = ""
                    isLoading = false
                }
                await refreshSuggestions()
            }
        }
    }

    private func startNewConversation() {
        currentConversationId = nil
        messages = [
            .init(id: UUID(), role: .system, text: "What's on your mind?")
        ]
        inputText = ""
        isLoading = false
        Task { await refreshSuggestions() }
    }
    
    private func sendToAPI(message: String, conversation: [ChatMessage]? = nil) async throws -> String {
        #if DEBUG
        print("🔐 Getting auth session...")
        #endif
        
        let session = try await authManager.supabase.auth.session
        
        #if DEBUG
        print("✅ Auth session obtained")
        print("   User ID: \(session.user.id)")
        print("   Access token length: \(session.accessToken.count) chars")
        #endif
        
        // Convert messages to OpenAI format
        let openAIMessages: [[String: String]]
        if let conv = conversation {
            openAIMessages = buildOpenAIMessages(conversation: conv)
        } else {
            openAIMessages = messages.map { msg in
                ["role": msg.role == .user ? "user" : msg.role == .assistant ? "assistant" : "system", "content": msg.text]
            } + [["role": "user", "content": message]]
        }
        return try await brightProcessorContent(for: openAIMessages, accessToken: session.accessToken)
    }

    // Build OpenAI-style messages array from a conversation snapshot
    private func buildOpenAIMessages(conversation: [ChatMessage]) -> [[String: String]] {
        conversation.map { msg in
            [
                "role": msg.role == .user ? "user" : msg.role == .assistant ? "assistant" : "system",
                "content": msg.text
            ]
        }
    }

    // Removed unused sendToAPIFull; consolidated into sendToAPI(_:conversation:)

    // MARK: - Networking
    /// Decodable model for the Edge Function response shape.
    private struct BrightResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    /// Shared helper to call the bright-processor Edge Function and return the first message content.
    private func brightProcessorContent(for messages: [[String: String]], accessToken: String) async throws -> String {
        struct Body: Encodable { let messages: [[String: String]] }
        guard let url = URL(string: "https://ppkqyfcnwajfzhvnqxec.supabase.co/functions/v1/bright-processor") else {
            throw ChatError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(Body(messages: messages))
        
        #if DEBUG
        print("🌐 Calling bright-processor API...")
        print("   URL: \(url.absoluteString)")
        print("   Messages count: \(messages.count)")
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ChatError.invalidResponse }
        
        #if DEBUG
        print("📡 Response status code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("   Response body: \(responseBody)")
            }
        }
        #endif
        
        if httpResponse.statusCode == 429 { throw ChatError.rateLimited }
        guard httpResponse.statusCode == 200 else { throw ChatError.serverError(httpResponse.statusCode) }
        let decoded = try JSONDecoder().decode(BrightResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else { throw ChatError.invalidResponse }
        
        #if DEBUG
        print("✅ Successfully received response from API")
        #endif
        
        return content
    }

    // Build and refresh short follow-up suggestions based on the conversation
    private func refreshSuggestions() async {
        await MainActor.run { isFetchingSuggestions = true }
        let snapshot: [ChatMessage] = await MainActor.run { messages }
        do {
            let proposed = try await fetchFollowUpSuggestions(conversation: snapshot)
            let final = Array(proposed.prefix(3))
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.1)) {
                    self.suggestions = final
                }
                self.isFetchingSuggestions = false
            }
        } catch {
            let fallback = defaultSuggestions(for: snapshot)
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.1)) {
                    self.suggestions = Array(fallback.prefix(3))
                }
                self.isFetchingSuggestions = false
            }
        }
    }

    private func fetchFollowUpSuggestions(conversation: [ChatMessage]) async throws -> [String] {
        let session = try await authManager.supabase.auth.session
        var convo = conversation
        let instruction = "Based on the conversation so far, propose three short, relevant follow-up questions the user might ask next. Respond ONLY with a JSON array of three strings. Each string must be 3-8 words."
        convo.append(ChatMessage(id: UUID(), role: .user, text: instruction))
        let content = try await brightProcessorContent(for: buildOpenAIMessages(conversation: convo), accessToken: session.accessToken)
        let parsed = parseSuggestions(from: content)
        if parsed.isEmpty { throw ChatError.invalidResponse }
        return parsed
    }

    /// Attempts to parse up to three suggestions from the model content.
    /// Accepts a JSON array or simple list/bullets fallback.
    private func parseSuggestions(from content: String) -> [String] {
        var text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove code fences if present
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Try to extract a JSON array substring
        if let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]"), start < end {
            let jsonString = String(text[start...end])
            if let data = jsonString.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                let items = arr.compactMap { $0 as? String }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !items.isEmpty { return Array(items.prefix(3)) }
            }
        }
        // Fallback: split lines/bullets
        let separators = CharacterSet(charactersIn: "\n\r")
        let rough = text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var cleaned: [String] = []
        for line in rough {
            var s = line
            if s.hasPrefix("- ") { s = String(s.dropFirst(2)) }
            if let dotRange = s.range(of: ". ") { // e.g., "1. Question"
                s = String(s[dotRange.upperBound...])
            }
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { cleaned.append(s) }
            if cleaned.count == 3 { break }
        }
        return cleaned
    }

    private func defaultSuggestions(for conversation: [ChatMessage]) -> [String] {
        return [
            "Can you expand on that?",
            "What should I reflect on?",
            "Any related verses to read?"
        ]
    }

    // Client-side typewriter animation for assistant message
    private func animateAssistantText(messageId: UUID, fullText: String) async {
        #if DEBUG
        print("🎬 Starting typewriter animation for text of length: \(fullText.count)")
        #endif
        var rendered = ""
        let characters = Array(fullText)
        // Determine a base delay based on length to keep long messages reasonable
        let length = max(1, characters.count)
        let baseCharDelayMs: UInt64 = length > 1200 ? 3 : (length > 800 ? 6 : (length > 400 ? 10 : 18))
        // Throttle UI updates for long messages to avoid heavy re-layouts
        let updateStride: Int = length > 1200 ? 6 : (length > 800 ? 4 : (length > 400 ? 3 : 1))
        var index = 0
        #if DEBUG
        print("⏱️ Base delay: \(baseCharDelayMs)ms per character")
        #endif
        for ch in characters {
            if Task.isCancelled { break }
            rendered.append(ch)
            let shouldForceUpdate = (ch == "." || ch == "?" || ch == "!" || ch == "," || ch == ":" || ch == ";" || ch == "\n")
            if updateStride == 1 || shouldForceUpdate || index % updateStride == 0 {
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                        messages[idx] = ChatMessage(id: messageId, role: .assistant, text: rendered)
                    }
                }
            }
            await Task.yield()
            // Slightly slower on punctuation/newlines for a natural feel
            let delayMs: UInt64
            switch ch {
            case ".", "?", "!": delayMs = baseCharDelayMs + 60
            case ",", ":", ";": delayMs = baseCharDelayMs + 35
            case "\n": delayMs = baseCharDelayMs + 40
            default: delayMs = baseCharDelayMs
            }
            try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
            index += 1
        }
        #if DEBUG
        print("✅ Typewriter animation complete")
        #endif
    }

    // Removed unused streaming implementation and related types
}

// MARK: - Message Components
private struct MessageRow: View, Equatable {
    let message: ChatMessage
    let isLoading: Bool
    let typingAssistantId: UUID?

    static func == (lhs: MessageRow, rhs: MessageRow) -> Bool {
        return lhs.message.id == rhs.message.id && lhs.message.text == rhs.message.text
    }

    var body: some View {
        Group {
            if message.role == .assistant || message.role == .system {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Faith:")
                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                        .foregroundStyle(StyleGuide.mainBrown.opacity(0.6))

                    if message.text.isEmpty && isLoading {
                        ThinkingIndicator()
                    } else {
                        BasicMarkdownText(
                            text: message.text,
                            enableLinking: true
                        )
                    }
                }
                .padding(.horizontal, 16)
            } else {
                HStack {
                    Spacer(minLength: 40)
                    UserBubble(text: message.text)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
private struct NeuromorphicInputBar: View {
    @Binding var text: String
    var onSubmit: () -> Void
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 12) {
            TextField(
                "",
                text: $text,
                prompt: Text("Send a message...")
                    .font(StyleGuide.merriweather(size: 16))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.38)),
                axis: .vertical
            )
            .font(StyleGuide.merriweather(size: 16))
            .foregroundColor(StyleGuide.mainBrown)
            .lineLimit(4)
            .focused(isFocused)
            .onSubmit { onSubmit() }

            Button(action: { onSubmit() }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    StyleGuide.backgroundBeige,
                                    StyleGuide.backgroundBeige.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 3, y: 3)
                        .shadow(color: Color.white.opacity(0.8), radius: 4, x: -3, y: -3)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? StyleGuide.mainBrown.opacity(0.35) : StyleGuide.mainBrown)
                        .animation(.easeInOut(duration: 0.2), value: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .buttonStyle(PressedButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 18)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            StyleGuide.backgroundBeige.opacity(0.95),
                            StyleGuide.backgroundBeige
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.white, radius: 6, x: -4, y: -4)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 4, y: 4)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .onTapGesture { isFocused.wrappedValue = true }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let dy = value.translation.height
                    if dy > 50 { isFocused.wrappedValue = false }
                }
        )
    }
}

// MARK: - Message Components
struct UserBubble: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Do not auto-link in user messages to avoid accidental links
            BasicMarkdownText(text: text, enableLinking: false)
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
struct BasicMarkdownText: View {
    let text: String
    var enableLinking: Bool = true
    var textColor: Color = StyleGuide.mainBrown
    @EnvironmentObject var bibleNavigator: BibleNavigator
    @Environment(\.openURL) private var openURL

    var body: some View {
        let ls = lines()
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(ls.indices, id: \.self) { idx in
                let line = ls[idx]
                if let header = parseHeader(line) {
                    Text(header.content)
                        .font(StyleGuide.merriweather(size: header.size, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, idx > 0 ? 8 : 0)
                } else if line.trimmingCharacters(in:  .whitespacesAndNewlines).isEmpty {
                    Text("")
                        .font(StyleGuide.merriweather(size: 4))
                        .frame(height: 12)
                } else {
                    if enableLinking {
                        lineWithLinks(line)
                    } else {
                        lineWithoutLinks(line)
                    }
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

    private func lineWithLinks(_ line: String) -> some View {
        let spans = splitBoldItalic(line)
        // Build attributed string with bold/italic and default color
        var attributed = AttributedString("")
        for span in spans {
            var a = AttributedString(span.text)
            if span.isBold && span.isItalic {
                a.font = StyleGuide.merriweather(size: 16, weight: .bold)
            } else if span.isBold {
                a.font = StyleGuide.merriweather(size: 16, weight: .bold)
            } else if span.isItalic {
                a.font = StyleGuide.merriweather(size: 16)
                a.inlinePresentationIntent = .emphasized
            } else {
                a.font = StyleGuide.merriweather(size: 16)
            }
            a.foregroundColor = textColor
            attributed.append(a)
        }

        // Link verse references anywhere in the line using NSAttributedString ranges
        let ns = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        // Replace non-breaking spaces with normal spaces to allow wrapping inside links
        ns.mutableString.replaceOccurrences(of: "\u{00A0}", with: " ", options: [], range: NSRange(location: 0, length: ns.length))
        ns.mutableString.replaceOccurrences(of: "\u{202F}", with: " ", options: [], range: NSRange(location: 0, length: ns.length))
        let text = ns.string
        let matches = BibleReferenceUtils.findMatches(in: text)
        for m in matches {
            if let url = BibleReferenceUtils.linkURL(for: m.selection) {
                let nsRange = NSRange(m.range, in: text)
                ns.addAttributes([
                    .link: url,
                    .foregroundColor: UIColor(StyleGuide.gold),
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: nsRange)
            }
        }
        let linked = AttributedString(ns)
        // Use UIKit-backed text view to ensure links are tappable
        return AnyView(
            LinkingText(attributed: linked, onOpen: { url in openURL(url) })
                .frame(maxWidth: .infinity, alignment: .leading)
        )
    }

    private func lineWithoutLinks(_ line: String) -> some View {
        let spans = splitBoldItalic(line)
        var attributed = AttributedString("")
        for span in spans {
            var a = AttributedString(span.text)
            if span.isBold && span.isItalic {
                a.font = StyleGuide.merriweather(size: 16, weight: .bold)
            } else if span.isBold {
                a.font = StyleGuide.merriweather(size: 16, weight: .bold)
            } else if span.isItalic {
                a.font = StyleGuide.merriweather(size: 16)
                a.inlinePresentationIntent = .emphasized
            } else {
                a.font = StyleGuide.merriweather(size: 16)
            }
            a.foregroundColor = textColor
            attributed.append(a)
        }
        // Normalize non-breaking spaces for consistent wrapping
        let ns = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        ns.mutableString.replaceOccurrences(of: "\u{00A0}", with: " ", options: [], range: NSRange(location: 0, length: ns.length))
        ns.mutableString.replaceOccurrences(of: "\u{202F}", with: " ", options: [], range: NSRange(location: 0, length: ns.length))
        let linked = AttributedString(ns)
        return AnyView(
            Text(linked)
                .multilineTextAlignment(.leading)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        )
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

// MARK: - UIKit-backed text view for reliable tappable links
private struct LinkingText: UIViewRepresentable {
    let attributed: AttributedString
    let onOpen: (URL) -> Void

    func makeUIView(context: Context) -> LinkableTextView {
        let tv = LinkableTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textAlignment = .left
        tv.font = UIFont(name: "Merriweather", size: 16)
        tv.textColor = UIColor(StyleGuide.mainBrown)
        tv.delegate = context.coordinator
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultHigh, for: .vertical)
        tv.linkTextAttributes = [
            .foregroundColor: UIColor(StyleGuide.gold),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return tv
    }

    func updateUIView(_ uiView: LinkableTextView, context: Context) {
        let base = NSAttributedString(attributed)
        let m = NSMutableAttributedString(attributedString: base)
        // Apply paragraph style for consistent spacing and alignment
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = 8
        ps.alignment = .left
        ps.lineBreakMode = .byWordWrapping
        if #available(iOS 14.0, *) {
            ps.lineBreakStrategy = []
        }
        m.addAttribute(.paragraphStyle, value: ps, range: NSRange(location: 0, length: m.length))
        m.addAttribute(.font, value: UIFont(name: "Merriweather", size: 16) as Any, range: NSRange(location: 0, length: m.length))
        m.addAttribute(.foregroundColor, value: UIColor(StyleGuide.mainBrown), range: NSRange(location: 0, length: m.length))
        
        uiView.attributedText = m
        uiView.textAlignment = .left
        uiView.tintColor = UIColor(StyleGuide.gold)
        uiView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onOpen: onOpen) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let onOpen: (URL) -> Void
        init(onOpen: @escaping (URL) -> Void) { self.onOpen = onOpen }
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            onOpen(URL)
            return false
        }
    }
}

// Custom UITextView subclass that properly reports intrinsic size
private class LinkableTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        // Calculate size based on current bounds width
        let width = bounds.width > 0 ? bounds.width : 300
        let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(size.height))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

// MARK: - Loading Indicator Components
private struct ThinkingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        AnimatedDotsView()
            .overlay(
                ShimmerView()
                    .mask(
                        AnimatedDotsView()
                    )
            )
    }
}

private struct AnimatedDotsView: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Text(".")
                    .font(StyleGuide.merriweather(size: 16, weight: .medium))
                    .foregroundStyle(StyleGuide.mainBrown.opacity(0.7))
                    .opacity(index < dotCount ? 1 : 0)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

private struct ShimmerView: View {
    @State private var shimmerPosition: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.3),
                    Color.white.opacity(0),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.3)
            .offset(x: shimmerPosition * (geometry.size.width + geometry.size.width * 0.3))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPosition = 1
                }
            }
        }
        .clipped()
    }
}

// MARK: - Suggestions UI Components
private struct SuggestionsRow: View {
    let suggestions: [String]
    var onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                    Button(action: { onTap(suggestion) }) {
                        SuggestionChip(text: suggestion)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct SuggestionChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StyleGuide.merriweather(size: 14))
            .foregroundStyle(StyleGuide.mainBrown)
            .lineLimit(1)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(StyleGuide.mainBrown.opacity(0.12), lineWidth: 1)
                    )
            )
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

// MARK: - Button Styles
private struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct BackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preference Keys
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
