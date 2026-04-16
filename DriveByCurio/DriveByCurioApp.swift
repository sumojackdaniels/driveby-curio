import SwiftUI
import CoreSwift

@main
struct DriveByCurioApp: App {
    private let appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState.tourCatalogStore)
                .environment(appState.tourPlayer)
                .environment(appState.locationService)
                .environment(appState.walkingTourStore)
                .environment(appState.walkingTourPlayer)
        }
    }
}
