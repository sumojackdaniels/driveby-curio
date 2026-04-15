import CoreLocation
import Observation

@Observable
@MainActor
final class POIRefreshController {
    let poiStore: POIStore
    let topicsStore: TopicsStore
    let poiService: POIService
    let announcementService: AudioAnnouncementService

    private var refreshTimer: Timer?
    private var lastRefreshLocation: CLLocation?

    static let refreshInterval: TimeInterval = 60
    static let significantDistance: Double = 500 // meters

    init(
        poiStore: POIStore,
        topicsStore: TopicsStore,
        poiService: POIService,
        announcementService: AudioAnnouncementService
    ) {
        self.poiStore = poiStore
        self.topicsStore = topicsStore
        self.poiService = poiService
        self.announcementService = announcementService
    }

    // MARK: - Timer Management

    func startRefreshTimer() {
        stopRefreshTimer()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.refreshIfNeeded(location: nil, heading: 0)
            }
        }
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Location Change Detection

    func isSignificantChange(from oldLocation: CLLocation?, to newLocation: CLLocation) -> Bool {
        guard let old = oldLocation else { return true }
        return old.distance(from: newLocation) >= Self.significantDistance
    }

    // MARK: - Refresh Logic

    func onLocationUpdate(_ location: CLLocation, heading: Double) async {
        if isSignificantChange(from: lastRefreshLocation, to: location) {
            await refreshIfNeeded(location: location, heading: heading)
        }

        updateClosestPOI(userLocation: location)
    }

    func refreshIfNeeded(location: CLLocation?, heading: Double) async {
        guard poiStore.canRefresh else { return }

        let topics = topicsStore.parsedTopics
        guard !topics.isEmpty else { return }

        guard let location else { return }

        poiStore.isLoading = true
        defer { poiStore.isLoading = false }

        do {
            let pois = try await poiService.fetchNearby(
                location: location,
                heading: heading,
                topics: topics
            )
            poiStore.pois = pois
            poiStore.lastRefresh = Date()
            lastRefreshLocation = location

            updateClosestPOI(userLocation: location)
        } catch {
            print("POI refresh failed: \(error)")
        }
    }

    // MARK: - Closest POI

    func updateClosestPOI(userLocation: CLLocation) {
        let closest = poiStore.pois.min(by: { a, b in
            let locA = CLLocation(latitude: a.lat, longitude: a.lng)
            let locB = CLLocation(latitude: b.lat, longitude: b.lng)
            return userLocation.distance(from: locA) < userLocation.distance(from: locB)
        })

        if closest?.id != poiStore.closestPOI?.id {
            poiStore.closestPOI = closest

            if let poi = closest {
                announcementService.announce(poi, userLocation: userLocation)
            }
        }
    }
}
