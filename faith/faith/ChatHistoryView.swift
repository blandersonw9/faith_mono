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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
                .onDelete { indexSet in
                    let current = store.listConversations()
                    for index in indexSet { Task { await store.deleteConversation(id: current[index].id) } }
                }
            }
            .listStyle(.plain)
            .background(StyleGuide.backgroundBeige)
            .scrollContentBackground(.hidden)
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(StyleGuide.backgroundBeige, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { 
                        dismiss() 
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                    .font(StyleGuide.merriweather(size: 16))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { onStartNew(); dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New")
                                .font(StyleGuide.merriweather(size: 16))
                        }
                        .foregroundColor(StyleGuide.mainBrown)
                    }
                }
            }
        }
        .background(StyleGuide.backgroundBeige.ignoresSafeArea())
    }
}


