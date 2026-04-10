import SwiftUI

@main
struct DriveByCurioApp: App {
    @State private var topicsStore = TopicsStore()
    @State private var poiStore = POIStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(topicsStore)
                .environment(poiStore)
        }
    }
}
