import Foundation
import CoreLocation

// MARK: - Walking Tour Data Model
//
// Supports both pre-authored tours (bundled with ElevenLabs audio) and
// user-created tours (recorded on-device). All tours are stored locally
// in v1 — no backend sync.

enum TourMode: String, Codable, CaseIterable, Identifiable {
    case walking, biking, driving

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walking: "Walking"
        case .biking: "Biking"
        case .driving: "Driving"
        }
    }

    var iconName: String {
        switch self {
        case .walking: "figure.walk"
        case .biking: "bicycle"
        case .driving: "car"
        }
    }
}

struct WalkingTour: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var creatorName: String
    var creatorIsLocal: Bool
    var description: String
    var tags: [String]
    var mode: TourMode
    var waypoints: [WalkingWaypoint]
    var createdAt: Date
    var updatedAt: Date
    var isAuthored: Bool  // true = pre-built ElevenLabs audio

    var totalStops: Int { waypoints.count }

    var estimatedDurationMinutes: Int {
        // Rough estimate: 3 min per stop (audio + walking between)
        waypoints.count * 3
    }

    static func == (lhs: WalkingTour, rhs: WalkingTour) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct WalkingWaypoint: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var order: Int
    var lat: Double
    var lng: Double
    var title: String
    var description: String
    var triggerRadiusMeters: Double  // Default 30m for walking
    var contentAudioFile: String?   // Main narration filename
    var navAudioFile: String?       // Nav instruction filename
    var narrationText: String?      // Source text for authored tours
    var navInstructionText: String? // Source text for authored tours

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: lat, longitude: lng)
    }

    static func == (lhs: WalkingWaypoint, rhs: WalkingWaypoint) -> Bool {
        lhs.id == rhs.id && lhs.order == rhs.order
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
