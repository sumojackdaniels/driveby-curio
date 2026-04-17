import Foundation
import CoreSwift

/// Shared app state for the walking-tour experience.
@MainActor
final class AppState {
    static let shared = AppState()

    let locationService = LocationService()
    let walkingTourStore: WalkingTourStore
    let walkingTourPlayer: WalkingTourPlayer

    private init() {
        self.walkingTourStore = WalkingTourStore()
        self.walkingTourPlayer = WalkingTourPlayer(locationService: locationService)
    }
}
