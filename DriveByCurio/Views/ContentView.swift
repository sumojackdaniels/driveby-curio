import SwiftUI
import CoreSwift

struct ContentView: View {
    @Environment(TopicsStore.self) var topicsStore
    @Environment(POIStore.self) var poiStore
    @Environment(LocationService.self) var locationService

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Location status
                LocationStatusView()

                // CarPlay connection status
                CarPlayConnectionView()

                // Topics editor
                TopicsEditorView()

                Spacer()
            }
            .padding()
            .navigationTitle("DriveByCurio")
        }
    }
}

struct CarPlayConnectionView: View {
    @Environment(POIStore.self) var poiStore

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

            if !poiStore.pois.isEmpty {
                Text("\(poiStore.pois.count) POIs")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1), in: Capsule())
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
