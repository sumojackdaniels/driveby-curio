import Foundation
import CoreLocation
import Observation

struct POI: Identifiable, Codable, Equatable {
    var id: String { name }
    let name: String
    let topics: [String]
    let description: String
    let lat: Double
    let lng: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

@Observable
@MainActor
final class POIStore {
    var pois: [POI] = []
    var closestPOI: POI?
    var lastRefresh: Date?
    var isLoading = false

    static let minimumRefreshInterval: TimeInterval = 60

    var canRefresh: Bool {
        guard let last = lastRefresh else { return true }
        return Date().timeIntervalSince(last) >= Self.minimumRefreshInterval
    }
}
