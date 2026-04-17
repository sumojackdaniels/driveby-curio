import Foundation

/// HTTP client for the curated-tour endpoints.
///
/// Uses URLSession directly rather than CoreSwift's APIClient because that
/// helper is POST-only and we want plain GETs for the tour catalog and
/// manifest. If GET support lands in CoreSwift later we can collapse this.
struct TourService {
    let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func fetchCatalog() async throws -> [TourSummary] {
        let url = baseURL.appendingPathComponent("/tours")
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TourCatalogResponse.self, from: data)
        return response.tours
    }

    func fetchTour(id: String) async throws -> Tour {
        let url = baseURL.appendingPathComponent("/tours/\(id)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Tour.self, from: data)
    }

    /// URL for the pre-synthesized mp3 of a single waypoint.
    /// Streamed directly by AVPlayer — we never download the whole file.
    func audioURL(tourId: String, waypointId: String) -> URL {
        baseURL.appendingPathComponent("/tours/\(tourId)/audio/\(waypointId).mp3")
    }
}
