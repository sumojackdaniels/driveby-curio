import SwiftUI
import CoreSwift

// Top-level iPhone view.
//
// The main surface is now the walking tour browser. The driving tours
// (CarPlay) browser is still accessible from the CarPlay scene but
// isn't the primary iPhone experience anymore.
struct ContentView: View {
    var body: some View {
        WalkingTourBrowserView()
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
