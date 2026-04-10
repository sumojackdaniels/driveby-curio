import Foundation
import CoreLocation
import CoreSwift

struct NearbyRequest: Encodable {
    let lat: Double
    let lng: Double
    let heading: Double
    let radius_km: Double
    let topics: [String]
}

struct NearbyResponse: Decodable {
    let pois: [POI]
}

struct POIService {
    let apiClient: APIClient

    init(baseURL: URL) {
        self.apiClient = APIClient(baseURL: baseURL)
    }

    func fetchNearby(
        location: CLLocation,
        heading: Double,
        radiusKm: Double = 10,
        topics: [String]
    ) async throws -> [POI] {
        let request = NearbyRequest(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            heading: heading,
            radius_km: radiusKm,
            topics: topics
        )
        let response: NearbyResponse = try await apiClient.post(path: "/nearby", body: request)
        return response.pois
    }
}
