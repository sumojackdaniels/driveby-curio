import Foundation

// Local storage for walking tours.
//
// Directory structure:
//   Documents/tours/{tourId}/tour.json
//   Documents/tours/{tourId}/{waypointId}/content.m4a
//   Documents/tours/{tourId}/{waypointId}/nav.m4a
//
// Pre-authored tours live in the app bundle under WalkingTours/{tourId}/

@MainActor
final class TourStorageService {

    static let shared = TourStorageService()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Directory paths

    private var toursDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("tours", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func tourDirectory(tourId: String) -> URL {
        let dir = toursDirectory.appendingPathComponent(tourId, isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func waypointDirectory(tourId: String, waypointId: String) -> URL {
        let dir = tourDirectory(tourId: tourId)
            .appendingPathComponent(waypointId, isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Save / Load user-created tours

    func saveTour(_ tour: WalkingTour) throws {
        let dir = tourDirectory(tourId: tour.id)
        let jsonURL = dir.appendingPathComponent("tour.json")
        let data = try encoder.encode(tour)
        try data.write(to: jsonURL, options: .atomic)
    }

    func loadUserTours() -> [WalkingTour] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: toursDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents.compactMap { dir in
            let jsonURL = dir.appendingPathComponent("tour.json")
            guard let data = try? Data(contentsOf: jsonURL),
                  let tour = try? decoder.decode(WalkingTour.self, from: data) else {
                return nil
            }
            return tour
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func deleteTour(tourId: String) {
        let dir = tourDirectory(tourId: tourId)
        try? fileManager.removeItem(at: dir)
    }

    // MARK: - Audio file URLs (user-created)

    func contentAudioURL(tourId: String, waypointId: String) -> URL {
        waypointDirectory(tourId: tourId, waypointId: waypointId)
            .appendingPathComponent("content.m4a")
    }

    func navAudioURL(tourId: String, waypointId: String) -> URL {
        waypointDirectory(tourId: tourId, waypointId: waypointId)
            .appendingPathComponent("nav.m4a")
    }

    // MARK: - Audio file URLs (authored tours — bundled in app)

    func authoredContentAudioURL(tourId: String, waypointId: String) -> URL? {
        // Try mp3 first (ElevenLabs output), then m4a
        Bundle.main.url(
            forResource: "content",
            withExtension: "mp3",
            subdirectory: "WalkingTours/\(tourId)/\(waypointId)"
        ) ?? Bundle.main.url(
            forResource: "content",
            withExtension: "m4a",
            subdirectory: "WalkingTours/\(tourId)/\(waypointId)"
        )
    }

    func authoredNavAudioURL(tourId: String, waypointId: String) -> URL? {
        Bundle.main.url(
            forResource: "nav",
            withExtension: "mp3",
            subdirectory: "WalkingTours/\(tourId)/\(waypointId)"
        ) ?? Bundle.main.url(
            forResource: "nav",
            withExtension: "m4a",
            subdirectory: "WalkingTours/\(tourId)/\(waypointId)"
        )
    }

    /// Resolve audio URL — checks authored bundle first, then user documents.
    func resolveContentAudioURL(tour: WalkingTour, waypoint: WalkingWaypoint) -> URL? {
        if tour.isAuthored {
            return authoredContentAudioURL(tourId: tour.id, waypointId: waypoint.id)
        }
        let url = contentAudioURL(tourId: tour.id, waypointId: waypoint.id)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func resolveNavAudioURL(tour: WalkingTour, waypoint: WalkingWaypoint) -> URL? {
        if tour.isAuthored {
            return authoredNavAudioURL(tourId: tour.id, waypointId: waypoint.id)
        }
        let url = navAudioURL(tourId: tour.id, waypointId: waypoint.id)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}
