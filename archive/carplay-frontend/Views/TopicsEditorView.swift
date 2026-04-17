import SwiftUI

struct TopicsEditorView: View {
    @Environment(TopicsStore.self) var topicsStore

    var body: some View {
        @Bindable var store = topicsStore
        VStack(alignment: .leading, spacing: 8) {
            Text("What interests you?")
                .font(.headline)
            Text("Enter topics, one per line. These guide what you'll learn about while driving.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $store.topicsText)
                .frame(minHeight: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.tertiary)
                )

            if !topicsStore.parsedTopics.isEmpty {
                Text("\(topicsStore.parsedTopics.count) topic\(topicsStore.parsedTopics.count == 1 ? "" : "s") configured")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
