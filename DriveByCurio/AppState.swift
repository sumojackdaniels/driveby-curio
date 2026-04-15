import Foundation
import CoreSwift

/// Shared app state accessible from both iPhone and CarPlay scenes.
@MainActor
final class AppState {
    static let shared = AppState()

    let topicsStore = TopicsStore()
    let poiStore = POIStore()
    let locationService = LocationService()
    let announcementService = AudioAnnouncementService()

    lazy var poiService: POIService = {
        let baseURL = URL(string: "https://curio-api-hdfess23ra-uc.a.run.app")!
        return POIService(baseURL: baseURL)
    }()

    lazy var refreshController: POIRefreshController = {
        POIRefreshController(
            poiStore: poiStore,
            topicsStore: topicsStore,
            poiService: poiService,
            announcementService: announcementService
        )
    }()

    private init() {}
}
