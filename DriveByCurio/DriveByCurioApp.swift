import SwiftUI
import CoreSwift

@main
struct DriveByCurioApp: App {
    private let appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState.topicsStore)
                .environment(appState.poiStore)
                .environment(appState.locationService)
        }
    }
}
