import Foundation
import SwiftUI
import Combine

// MARK: - Models
struct StoredConversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var model: String?
    var messages: [StoredMessage]
}

struct StoredMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable { case system, user, assistant }
    let id: UUID
    var role: Role
    var text: String
    var createdAt: Date
}

// MARK: - Chat Store (JSON-backed)
final class ChatStore: ObservableObject {
    static let shared = ChatStore()
    private init() { Task { await loadFromDisk() } }
    
    @Published private(set) var conversations: [StoredConversation] = []
    
    // File URL in Application Support to be backed up and not visible to users
    private var fileURL: URL {
        let manager = FileManager.default
        let base = try? manager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let bundleId = Bundle.main.bundleIdentifier ?? "faith.app"
        let dir = base?.appendingPathComponent(bundleId, isDirectory: true)
        if let dir, !manager.fileExists(atPath: dir.path) { try? manager.createDirectory(at: dir, withIntermediateDirectories: true) }
        return (dir ?? manager.temporaryDirectory).appendingPathComponent("chat_history.json")
    }
    
    // MARK: - Public API
    @MainActor
    func listConversations() -> [StoredConversation] {
        conversations.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    @MainActor
    func upsertConversation(from chatMessages: [ChatMessage], existingId: UUID? = nil, titleFallback: String = "Conversation") async -> StoredConversation {
        let now = Date()
        let title = makeTitle(from: chatMessages) ?? titleFallback
        let msgs: [StoredMessage] = chatMessages.map { m in
            StoredMessage(
                id: m.id,
                role: .init(from: m.role),
                text: m.text,
                createdAt: now
            )
        }
        if let id = existingId, let idx = conversations.firstIndex(where: { $0.id == id }) {
            conversations[idx].messages = msgs
            conversations[idx].updatedAt = now
            conversations[idx].title = title
            await persist()
            return conversations[idx]
        } else {
            let convo = StoredConversation(id: UUID(), title: title, createdAt: now, updatedAt: now, model: nil, messages: msgs)
            conversations.append(convo)
            await persist()
            return convo
        }
    }
    
    @MainActor
    func deleteConversation(id: UUID) async {
        conversations.removeAll { $0.id == id }
        await persist()
    }
    
    @MainActor
    func loadConversation(id: UUID) -> [ChatMessage]? {
        guard let convo = conversations.first(where: { $0.id == id }) else { return nil }
        return convo.messages.map { ChatMessage(id: $0.id, role: $0.role.toChatRole(), text: $0.text) }
    }
    
    // MARK: - Persistence
    private func loadFromDisk() async {
        let url = fileURL
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([StoredConversation].self, from: data)
            await MainActor.run { self.conversations = decoded }
        } catch {
            // If decode fails, keep empty list but don't crash
        }
    }
    
    @MainActor
    private func persist() async {
        let url = fileURL
        do {
            let data = try JSONEncoder().encode(conversations)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Ignore write errors in this minimal implementation
        }
    }
    
    private func makeTitle(from messages: [ChatMessage]) -> String? {
        // Prefer first user message as title, truncated
        if let firstUser = messages.first(where: { $0.role == .user })?.text {
            let trimmed = firstUser.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return String(trimmed.prefix(48))
        }
        return nil
    }
}

// MARK: - Mappers
private extension StoredMessage.Role {
    init(from role: ChatMessage.Role) {
        switch role {
        case .system: self = .system
        case .user: self = .user
        case .assistant: self = .assistant
        }
    }
    func toChatRole() -> ChatMessage.Role {
        switch self {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        }
    }
}


