import SwiftUI
import CoreSwift

struct ContentView: View {
    @Environment(TopicsStore.self) var topicsStore
    @Environment(POIStore.self) var poiStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Location status
                LocationStatusView()

                // Topics editor
                TopicsEditorView()

                Spacer()
            }
            .padding()
            .navigationTitle("DriveByCurio")
        }
    }
}

struct LocationStatusView: View {
    var body: some View {
        // TODO: Show location authorization status and prompt
        Text("Location: pending")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

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
        }
    }
}
