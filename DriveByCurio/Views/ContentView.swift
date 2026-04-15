import SwiftUI
import CoreSwift

// Top-level iPhone view.
//
// Milestone 1 (curated tours) replaces the old POI/topics-heavy ContentView
// with a tour browser. The legacy live-mode UI (TopicsEditorView etc.)
// remains in the codebase but is not currently linked into the navigation —
// it will come back as a tab once Mode 2 is rebuilt for the Audio category.
struct ContentView: View {
    var body: some View {
        TourBrowserView()
    }
}

struct CarPlayConnectionView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CarPlaySceneDelegate.isConnected ? "car.fill" : "car")
                .foregroundStyle(CarPlaySceneDelegate.isConnected ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("CarPlay")
                    .font(.subheadline.weight(.medium))
                Text(CarPlaySceneDelegate.isConnected ? "Connected" : "Not connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
