import Foundation
import CoreSwift

/// Shared app state accessible from both iPhone and CarPlay scenes.
///
/// Two concerns live here:
///   - Curated tours (the post-MVP direction): tourService, tourCatalogStore,
///     tourPlayer, locationService.
///   - Live mode / nearby POIs (the original MVP, kept around so the iPhone
///     build still compiles and the /nearby endpoint is still reachable):
///     topicsStore, poiStore, poiService, refreshController,
///     announcementService.
///
/// Live mode is no longer wired into the CarPlay scene — the CarPlay scene
/// is now an Audio-category app surfacing tours only. Live mode survives as
/// pre-existing iPhone-side plumbing and will be removed in a follow-up.
@MainActor
final class AppState {
    static let shared = AppState()

    // Backend base URL — the deployed Cloud Run service.
    private static let backendBaseURL = URL(string: "https://curio-api-1096302431561.us-central1.run.app")!

    // Shared
    let locationService = LocationService()

    // Tours
    let tourService: TourService
    let tourCatalogStore: TourCatalogStore
    let tourPlayer: TourPlayer

    // Legacy (live mode / MVP — kept compiling, unused on CarPlay)
    let topicsStore = TopicsStore()
    let poiStore = POIStore()
    let announcementService = AudioAnnouncementService()
    let poiService: POIService
    lazy var refreshController: POIRefreshController = {
        POIRefreshController(
            poiStore: poiStore,
            topicsStore: topicsStore,
            poiService: poiService,
            announcementService: announcementService
        )
    }()

    private init() {
        let baseURL = Self.backendBaseURL
        self.tourService = TourService(baseURL: baseURL)
        self.tourCatalogStore = TourCatalogStore(service: tourService)
        self.tourPlayer = TourPlayer(tourService: tourService, locationService: locationService)
        self.poiService = POIService(baseURL: baseURL)
    }
}
