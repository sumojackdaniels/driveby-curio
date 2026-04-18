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

    /// Default cover images for user tours by keyword match.
    private static let defaultCoverImages: [(keyword: String, imageName: String)] = [
        ("rock creek", "TourImages/rock-creek-hero"),
    ]

    func loadAll() {
        authoredTours = AuthoredWalkingTours.all
        userTours = storage.loadUserTours().map { tour in
            var t = tour
            if t.coverImageName == nil {
                for entry in Self.defaultCoverImages where t.title.localizedCaseInsensitiveContains(entry.keyword) {
                    t.coverImageName = entry.imageName
                    break
                }
            }
            return t
        }
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
