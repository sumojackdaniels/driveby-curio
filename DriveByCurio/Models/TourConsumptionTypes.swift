import Foundation
import CoreLocation

// MARK: - Tour Consumption Primitives
//
// Three primitives structure a tour for consumption:
//   Stops    — places you walk/bike to; anchor the tour to physical locations.
//   Segments — content pieces at a stop (narration, interview, poem, field recording, photo, note).
//   Paths    — connecting routes between consecutive stops (walk/bike estimates).
//
// Existing WalkingTour/WalkingWaypoint data is bridged via computed properties
// so authored tours work without migration.

// MARK: - Segment

/// A single piece of content consumed at a stop.
struct TourSegment: Identifiable, Equatable {
    let id: String
    var kind: SegmentKind
    var title: String
    var description: String
    var durationMinutes: Int
    var audioFile: String?

    enum SegmentKind: String, CaseIterable {
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

// MARK: - Path

/// The route between two consecutive stops.
struct TourPath: Equatable {
    var walkMinutes: Int
    var bikeMinutes: Int
    var distanceFeet: Int
    var note: String?

    var distanceMiles: Double {
        Double(distanceFeet) / 5280.0
    }
}

// MARK: - Author

/// Richer author metadata for display in the consumption UI.
struct TourAuthor: Equatable {
    var name: String
    var role: String
    var initials: String

    init(name: String, role: String = "", initials: String? = nil) {
        self.name = name
        self.role = role
        self.initials = initials ?? String(
            name.split(separator: " ")
                .prefix(2)
                .compactMap(\.first)
                .map(String.init)
                .joined()
        )
    }
}

// MARK: - WalkingWaypoint Extensions (Segment Synthesis)

extension WalkingWaypoint {
    /// Synthesizes segments from the waypoint's existing audio content.
    /// Each waypoint becomes a stop with one narration segment.
    var synthesizedSegments: [TourSegment] {
        let estimatedMinutes = max(1, (narrationText?.count ?? 600) / 150) // ~150 words/min
        return [
            TourSegment(
                id: "\(id)-narration",
                kind: .narration,
                title: title,
                description: description,
                durationMinutes: estimatedMinutes,
                audioFile: contentAudioFile
            )
        ]
    }

    /// The address string derived from the waypoint description, or a fallback.
    var displayAddress: String {
        description
    }
}

// MARK: - WalkingTour Extensions (Path & Author Synthesis)

extension WalkingTour {
    /// Author info synthesized from existing creator fields.
    var author: TourAuthor {
        TourAuthor(
            name: creatorName,
            role: creatorIsLocal ? "Local resident" : "Guide"
        )
    }

    /// Paths between consecutive waypoints, computed from GPS coordinates.
    var synthesizedPaths: [TourPath] {
        let sorted = waypoints.sorted { $0.order < $1.order }
        guard sorted.count >= 2 else { return [] }

        return zip(sorted, sorted.dropFirst()).map { from, to in
            let meters = from.clLocation.distance(from: to.clLocation)
            let feet = Int(meters * 3.28084)
            // ~264 ft/min walking (~3 mph), ~880 ft/min biking (~10 mph)
            let walkMin = max(1, Int(ceil(Double(feet) / 264.0)))
            let bikeMin = max(1, Int(ceil(Double(feet) / 880.0)))
            return TourPath(
                walkMinutes: walkMin,
                bikeMinutes: bikeMin,
                distanceFeet: feet
            )
        }
    }

    /// Total walking time across all paths.
    var totalWalkMinutes: Int {
        synthesizedPaths.reduce(0) { $0 + $1.walkMinutes }
    }

    /// Total biking time across all paths.
    var totalBikeMinutes: Int {
        synthesizedPaths.reduce(0) { $0 + $1.bikeMinutes }
    }

    /// Total distance in miles.
    var totalDistanceMiles: Double {
        let totalFeet = synthesizedPaths.reduce(0) { $0 + $1.distanceFeet }
        return Double(totalFeet) / 5280.0
    }

    /// Sorted waypoints (stops) for consumption.
    var sortedStops: [WalkingWaypoint] {
        waypoints.sorted { $0.order < $1.order }
    }

    /// Starting address (first stop's description).
    var startAddress: String {
        sortedStops.first?.displayAddress ?? ""
    }

    /// A representative quote from the tour (first line of the description).
    var coverQuote: String {
        description
    }
}
