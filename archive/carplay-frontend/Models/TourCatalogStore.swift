import Foundation
import Observation

@Observable
@MainActor
final class TourCatalogStore {
    var tours: [TourSummary] = []
    var isLoading: Bool = false
    var lastError: String?

    private let service: TourService

    init(service: TourService) {
        self.service = service
    }

    func loadCatalog() async {
        isLoading = true
        lastError = nil
        do {
            tours = try await service.fetchCatalog()
        } catch {
            lastError = String(describing: error)
            print("TourCatalogStore: failed to load: \(error)")
        }
        isLoading = false
    }

    func fetchTour(id: String) async -> Tour? {
        do {
            return try await service.fetchTour(id: id)
        } catch {
            lastError = String(describing: error)
            print("TourCatalogStore: failed to fetch tour \(id): \(error)")
            return nil
        }
    }
}
