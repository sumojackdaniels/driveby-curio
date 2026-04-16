import Foundation
import Observation

// Central store for all walking tours — both pre-authored (bundled)
// and user-created (local storage).

@Observable
@MainActor
final class WalkingTourStore {
    private(set) var authoredTours: [WalkingTour] = []
    private(set) var userTours: [WalkingTour] = []

    var allTours: [WalkingTour] {
        authoredTours + userTours
    }

    private let storage = TourStorageService.shared

    init() {
        loadAll()
    }

    func loadAll() {
        authoredTours = AuthoredWalkingTours.all
        userTours = storage.loadUserTours()
    }

    func saveUserTour(_ tour: WalkingTour) {
        try? storage.saveTour(tour)
        loadAll()
    }

    func deleteUserTour(tourId: String) {
        storage.deleteTour(tourId: tourId)
        loadAll()
    }
}
