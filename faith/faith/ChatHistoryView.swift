import SwiftUI

struct ChatHistoryView: View {
    @ObservedObject var store: ChatStore
    var onSelect: (UUID) -> Void
    var onStartNew: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.listConversations()) { convo in
                    Button(action: { onSelect(convo.id); dismiss() }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(convo.title)
                                .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown)
                            Text(convo.updatedAt, style: .relative)
                                .font(StyleGuide.merriweather(size: 12))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    let current = store.listConversations()
                    for index in indexSet { Task { await store.deleteConversation(id: current[index].id) } }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { onStartNew(); dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("New")
                        }
                    }
                }
            }
        }
    }
}


