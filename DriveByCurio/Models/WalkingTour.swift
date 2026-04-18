import Foundation
import CoreLocation

// MARK: - Walking Tour Data Model
//
// v2 data model: stops, segments, paths, and author are all first-class.
//
// Supports both pre-authored tours (bundled with ElevenLabs audio) and
// user-created tours (recorded on-device). All tours are stored locally
// in v1 — no backend sync.
//
// Migration: The legacy flat WalkingWaypoint format is decoded via
// WalkingTour's custom Codable conformance (see bottom of file).

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

// MARK: - Tour Author

/// Rich author metadata for display in the consumption UI.
struct TourAuthor: Codable, Equatable, Hashable {
    var name: String
    var role: String
    var bio: String
    var initials: String

    init(name: String, role: String = "", bio: String = "", initials: String? = nil) {
        self.name = name
        self.role = role
        self.bio = bio
        self.initials = initials ?? String(
            name.split(separator: " ")
                .prefix(2)
                .compactMap(\.first)
                .map(String.init)
                .joined()
        )
    }
}

// MARK: - Tour Segment

/// A single piece of content consumed at a stop.
struct TourSegment: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var kind: SegmentKind
    var title: String
    var description: String
    var durationSeconds: Int
    var audioFile: String?
    var narrationText: String?

    var durationMinutes: Int {
        max(1, durationSeconds / 60)
    }

    enum SegmentKind: String, Codable, CaseIterable {
        case narration
        case interview
        case poem
        case photo
        case fieldRecording = "field"
        case note

        var label: String {
            switch self {
            case .narration: "Narration"
            case .interview: "Interview"
            case .poem: "Reading"
            case .photo: "Photo"
            case .fieldRecording: "Field recording"
            case .note: "Note"
            }
        }

        var iconName: String {
            switch self {
            case .narration: "waveform"
            case .interview: "person.2.fill"
            case .poem: "quote.opening"
            case .photo: "photo"
            case .fieldRecording: "dot.radiowaves.left.and.right"
            case .note: "doc.text"
            }
        }
    }
}

// MARK: - Tour Stop

/// A physical location on the tour with one or more content segments.
struct TourStop: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var order: Int
    var title: String
    var description: String
    var address: String
    var lat: Double
    var lng: Double
    var triggerRadiusMeters: Double
    var segments: [TourSegment]
    var navAudioFile: String?
    var navInstructionText: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: lat, longitude: lng)
    }

    static func == (lhs: TourStop, rhs: TourStop) -> Bool {
        lhs.id == rhs.id && lhs.order == rhs.order
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Tour Path

/// The route between two consecutive stops.
struct TourPath: Codable, Equatable, Hashable {
    var walkMinutes: Int
    var bikeMinutes: Int
    var distanceFeet: Int
    var note: String?

    var distanceMiles: Double {
        Double(distanceFeet) / 5280.0
    }
}

// MARK: - Walking Tour

struct WalkingTour: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var author: TourAuthor
    var description: String
    var tags: [String]
    var mode: TourMode
    var stops: [TourStop]
    var paths: [TourPath]
    var coverImageName: String?  // Asset catalog image name (e.g. "TourImages/postwar-dreams-hero")
    var createdAt: Date
    var updatedAt: Date
    var isAuthored: Bool  // true = pre-built ElevenLabs audio

    var totalStops: Int { stops.count }

    var estimatedDurationMinutes: Int {
        let segmentMinutes = stops.flatMap(\.segments).reduce(0) { $0 + $1.durationMinutes }
        let transitMinutes = totalWalkMinutes
        return segmentMinutes + transitMinutes
    }

    /// Sorted stops for display.
    var sortedStops: [TourStop] {
        stops.sorted { $0.order < $1.order }
    }

    /// Total walking time across all paths.
    var totalWalkMinutes: Int {
        paths.reduce(0) { $0 + $1.walkMinutes }
    }

    /// Total biking time across all paths.
    var totalBikeMinutes: Int {
        paths.reduce(0) { $0 + $1.bikeMinutes }
    }

    /// Total distance in miles.
    var totalDistanceMiles: Double {
        let totalFeet = paths.reduce(0) { $0 + $1.distanceFeet }
        return Double(totalFeet) / 5280.0
    }

    /// Starting address (first stop's address).
    var startAddress: String {
        sortedStops.first?.address ?? ""
    }

    /// A representative quote from the tour (first sentence of the description).
    var coverQuote: String {
        if let range = description.range(of: ".", options: .literal) {
            let firstSentence = String(description[description.startIndex..<range.upperBound])
            if firstSentence.count < description.count {
                return String(firstSentence.dropLast())
            }
        }
        return description
    }

    static func == (lhs: WalkingTour, rhs: WalkingTour) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Codable (with legacy migration)

    enum CodingKeys: String, CodingKey {
        case id, title, author, description, tags, mode
        case stops, paths, coverImageName
        case createdAt, updatedAt, isAuthored
        // Legacy keys
        case creatorName, creatorIsLocal, waypoints
    }

    init(
        id: String,
        title: String,
        author: TourAuthor,
        description: String,
        tags: [String],
        mode: TourMode,
        stops: [TourStop],
        paths: [TourPath],
        coverImageName: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        isAuthored: Bool
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.tags = tags
        self.mode = mode
        self.stops = stops
        self.paths = paths
        self.coverImageName = coverImageName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isAuthored = isAuthored
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        tags = try container.decode([String].self, forKey: .tags)
        mode = try container.decode(TourMode.self, forKey: .mode)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isAuthored = try container.decode(Bool.self, forKey: .isAuthored)
        coverImageName = try container.decodeIfPresent(String.self, forKey: .coverImageName)

        // Try new format first
        if let newAuthor = try? container.decode(TourAuthor.self, forKey: .author) {
            author = newAuthor
            stops = try container.decode([TourStop].self, forKey: .stops)
            paths = try container.decode([TourPath].self, forKey: .paths)
        } else {
            // Legacy format: migrate from flat waypoints
            let creatorName = try container.decode(String.self, forKey: .creatorName)
            let creatorIsLocal = try container.decode(Bool.self, forKey: .creatorIsLocal)
            author = TourAuthor(
                name: creatorName,
                role: creatorIsLocal ? "Local guide" : "Guide"
            )

            let waypoints = try container.decode([LegacyWaypoint].self, forKey: .waypoints)
            stops = waypoints.map { wp in
                let estimatedSeconds = max(60, (wp.narrationText?.count ?? 600) / 150 * 60)
                let segment = TourSegment(
                    id: "\(wp.id)-narration",
                    kind: .narration,
                    title: wp.title,
                    description: wp.description,
                    durationSeconds: estimatedSeconds,
                    audioFile: wp.contentAudioFile,
                    narrationText: wp.narrationText
                )
                return TourStop(
                    id: wp.id,
                    order: wp.order,
                    title: wp.title,
                    description: wp.description,
                    address: wp.description,
                    lat: wp.lat,
                    lng: wp.lng,
                    triggerRadiusMeters: wp.triggerRadiusMeters,
                    segments: [segment],
                    navAudioFile: wp.navAudioFile,
                    navInstructionText: wp.navInstructionText
                )
            }

            // Compute paths from GPS coordinates
            let sorted = stops.sorted { $0.order < $1.order }
            if sorted.count >= 2 {
                paths = zip(sorted, sorted.dropFirst()).map { from, to in
                    let meters = from.clLocation.distance(from: to.clLocation)
                    let feet = Int(meters * 3.28084)
                    let walkMin = max(1, Int(ceil(Double(feet) / 264.0)))
                    let bikeMin = max(1, Int(ceil(Double(feet) / 880.0)))
                    return TourPath(walkMinutes: walkMin, bikeMinutes: bikeMin, distanceFeet: feet)
                }
            } else {
                paths = []
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
        try container.encode(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
        try container.encode(mode, forKey: .mode)
        try container.encode(stops, forKey: .stops)
        try container.encode(paths, forKey: .paths)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isAuthored, forKey: .isAuthored)
    }
}

// MARK: - Legacy Waypoint (for migration only)

/// Used only during decoding of old-format tour JSON.
private struct LegacyWaypoint: Codable {
    let id: String
    var order: Int
    var lat: Double
    var lng: Double
    var title: String
    var description: String
    var triggerRadiusMeters: Double
    var contentAudioFile: String?
    var navAudioFile: String?
    var narrationText: String?
    var navInstructionText: String?
}
