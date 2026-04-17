import Foundation
import CoreLocation

// Swift mirror of backend/src/tours/types.ts. Field names match the JSON
// payload (snake_case) so JSONDecoder can decode without a custom keys block.
//
// These models are vendored in the app target rather than core-swift because
// core-swift is fetched via SPM from a separate GitHub repo and adding to it
// would require a separate PR cycle. The contract is small enough that the
// duplication cost is acceptable for milestone 1; if a second consumer
// (e.g. a watchOS companion) ever needs Tour types we'll promote them.

struct TourWaypoint: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let order: Int
    let lat: Double
    let lng: Double
    let title: String
    let subject: String
    let trigger_radius_m: Double
    let narration_text: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: lat, longitude: lng)
    }
}

struct Tour: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let region: String
    let duration_minutes: Int
    let distance_km: Double
    let cover_image_url: String?
    let author: String
    let waypoints: [TourWaypoint]
}

/// Catalog DTO returned by `GET /tours`.
struct TourSummary: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let region: String
    let duration_minutes: Int
    let distance_km: Double
    let cover_image_url: String?
    let author: String
    let waypoint_count: Int
}

struct TourCatalogResponse: Codable {
    let tours: [TourSummary]
}
