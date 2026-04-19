import Foundation

// MARK: - Tour Progress
//
// Per-tour playback snapshot for later resumption. Persisted to
// UserDefaults by `TourProgressStore`. When the user switches from
// tour A to tour B mid-play, the player saves A's progress here so we
// can later resume from where they left off.

struct TourProgress: Codable, Equatable, Hashable {
    let tourId: String
    var stopIndex: Int
    var segmentIndex: Int
    var audioTime: TimeInterval
    var savedAt: Date
}

// MARK: - Tour Progress Store
//
// A lightweight UserDefaults-backed map of `tourId -> TourProgress`.
// Kept separate from `WalkingTourStore` so the catalog model stays
// decoupled from ephemeral playback state.

@MainActor
@Observable
final class TourProgressStore {
    /// Shared instance backed by `UserDefaults.standard`. Pass a custom
    /// `UserDefaults` to `init(defaults:)` in tests.
    static let shared = TourProgressStore()

    private static let defaultsKey = "com.driveby.tourProgress.v1"

    private let defaults: UserDefaults
    private(set) var progressByTour: [String: TourProgress] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromDisk()
    }

    /// Save or overwrite progress for one tour.
    func save(_ progress: TourProgress) {
        progressByTour[progress.tourId] = progress
        persist()
    }

    /// Retrieve the saved progress for a tour, if any.
    func progress(for tourId: String) -> TourProgress? {
        progressByTour[tourId]
    }

    /// Clear saved progress for a tour (e.g. on completion).
    func clear(tourId: String) {
        progressByTour.removeValue(forKey: tourId)
        persist()
    }

    /// Clear all saved progress (test utility / "reset" affordance).
    func clearAll() {
        progressByTour.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = defaults.data(forKey: Self.defaultsKey) else { return }
        let decoder = JSONDecoder()
        if let map = try? decoder.decode([String: TourProgress].self, from: data) {
            progressByTour = map
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(progressByTour) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
