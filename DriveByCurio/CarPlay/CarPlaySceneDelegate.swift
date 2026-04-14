import CarPlay
import CoreLocation
import MapKit
import CoreSwift

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private var templateApplicationScene: CPTemplateApplicationScene?

    // Shared state — injected from app-level stores
    static var shared: CarPlaySceneDelegate?
    @MainActor static var isConnected = false

    private var poiStore: POIStore { AppState.shared.poiStore }
    private var topicsStore: TopicsStore { AppState.shared.topicsStore }
    private var locationService: LocationService { AppState.shared.locationService }
    private var refreshController: POIRefreshController { AppState.shared.refreshController }
    private var announcementService: AudioAnnouncementService { AppState.shared.announcementService }

    private var poiTemplate: CPPointOfInterestTemplate?
    private var topicsTemplate: CPListTemplate?
    private var locationObserver: NSObjectProtocol?

    // MARK: - Scene Lifecycle

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        self.templateApplicationScene = templateApplicationScene
        Self.shared = self

        Task { @MainActor in
            Self.isConnected = true
            setupTabBar()
            locationService.startUpdating()
            refreshController.startRefreshTimer()
            startLocationObservation()
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        Task { @MainActor in
            Self.isConnected = false
            refreshController.stopRefreshTimer()
            locationService.stopUpdating()
        }
        self.interfaceController = nil
        self.templateApplicationScene = nil
        Self.shared = nil
    }

    // MARK: - Tab Bar Setup

    @MainActor
    private func setupTabBar() {
        // Tab 1: Nearby POIs
        let poiTemplate = createPOITemplate()
        self.poiTemplate = poiTemplate

        // Tab 2: Topics
        let topicsTemplate = createTopicsTemplate()
        self.topicsTemplate = topicsTemplate

        let tabBar = CPTabBarTemplate(templates: [poiTemplate, topicsTemplate])
        interfaceController?.setRootTemplate(tabBar, animated: false)
    }

    // MARK: - POI Template

    @MainActor
    private func createPOITemplate() -> CPPointOfInterestTemplate {
        let pois = buildCPPointsOfInterest()
        let template = CPPointOfInterestTemplate(title: "Nearby", pointsOfInterest: pois, selectedIndex: NSNotFound)
        template.tabTitle = "Nearby"
        template.tabImage = UIImage(systemName: "mappin.and.ellipse")
        template.pointOfInterestDelegate = self
        return template
    }

    @MainActor
    private func buildCPPointsOfInterest() -> [CPPointOfInterest] {
        let displayPOIs = Array(poiStore.pois.prefix(12))

        return displayPOIs.map { poi in
            let coordinate = CLLocationCoordinate2D(latitude: poi.lat, longitude: poi.lng)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = poi.name

            let cpPOI = CPPointOfInterest(
                location: mapItem,
                title: poi.name,
                subtitle: poi.topics.joined(separator: ", "),
                summary: nil,
                detailTitle: poi.name,
                detailSubtitle: poi.topics.joined(separator: ", "),
                detailSummary: poi.description,
                pinImage: UIImage(systemName: "mappin.circle.fill")
            )
            cpPOI.userInfo = poi
            return cpPOI
        }
    }

    @MainActor
    func refreshPOITemplate() {
        guard let poiTemplate else { return }
        let newPOIs = buildCPPointsOfInterest()
        poiTemplate.setPointsOfInterest(newPOIs, selectedIndex: NSNotFound)
    }

    // MARK: - POI Detail (CPInformationTemplate)

    @MainActor
    private func showPOIDetail(_ poi: POI) {
        guard let interfaceController else { return }

        // Calculate distance and direction from current location
        var distanceText = ""
        if let userLocation = locationService.currentLocation {
            let poiLocation = CLLocation(latitude: poi.lat, longitude: poi.lng)
            let distance = userLocation.distance(from: poiLocation)
            let formatted = HeadingCalculator.formatDistance(distance)
            let bearing = HeadingCalculator.bearingBetween(
                from: userLocation.coordinate,
                to: poi.coordinate
            )
            let direction = HeadingCalculator.compassDirection(degrees: bearing)
            distanceText = "\(formatted) \(direction)"
        }

        let items: [CPInformationItem] = [
            CPInformationItem(title: "Topics", detail: poi.topics.joined(separator: ", ")),
            CPInformationItem(title: "About", detail: poi.description),
            CPInformationItem(title: "Distance", detail: distanceText.isEmpty ? "Calculating..." : distanceText),
        ]

        let openInMaps = CPTextButton(title: "Open in Maps", textStyle: .normal) { [weak self] _ in
            let coordinate = CLLocationCoordinate2D(latitude: poi.lat, longitude: poi.lng)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = poi.name
            let url = URL(string: "maps://?ll=\(poi.lat),\(poi.lng)&q=\(poi.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? poi.name)")!
            self?.templateApplicationScene?.open(url, options: nil)
        }

        let infoTemplate = CPInformationTemplate(
            title: poi.name,
            layout: .twoColumn,
            items: items,
            actions: [openInMaps]
        )

        interfaceController.pushTemplate(infoTemplate, animated: true)
    }

    // MARK: - Topics Template

    @MainActor
    private func createTopicsTemplate() -> CPListTemplate {
        let items = buildTopicsListItems()
        let section = CPListSection(items: items, header: "Your Interests", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Topics", sections: [section])
        template.tabTitle = "Topics"
        template.tabImage = UIImage(systemName: "list.star")
        template.emptyViewTitleVariants = ["No Topics"]
        template.emptyViewSubtitleVariants = ["Open DriveByCurio on your iPhone to set your interests"]
        return template
    }

    @MainActor
    private func buildTopicsListItems() -> [CPListItem] {
        let topics = topicsStore.parsedTopics
        guard !topics.isEmpty else { return [] }

        return topics.map { topic in
            let item = CPListItem(text: topic, detailText: nil)
            item.handler = { _, completion in completion() }
            return item
        }
    }

    @MainActor
    func refreshTopicsTemplate() {
        guard let topicsTemplate else { return }
        let items = buildTopicsListItems()
        let section = CPListSection(items: items, header: "Your Interests", sectionIndexTitle: nil)
        topicsTemplate.updateSections([section])
    }

    // MARK: - Location Observation

    private func startLocationObservation() {
        // Use a timer to periodically check for location updates and refresh POIs
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let location = self.locationService.currentLocation else { return }

                let heading = self.locationService.currentHeading?.trueHeading ?? 0
                await self.refreshController.onLocationUpdate(location, heading: heading)
                self.refreshPOITemplate()
            }
        }
    }
}

// MARK: - CPPointOfInterestTemplateDelegate

extension CarPlaySceneDelegate: CPPointOfInterestTemplateDelegate {
    nonisolated func pointOfInterestTemplate(
        _ pointOfInterestTemplate: CPPointOfInterestTemplate,
        didChangeMapRegion region: MKCoordinateRegion
    ) {
        // CarPlay delivers this from an XPC background thread — keep it
        // nonisolated and hop to MainActor only when we touch state.
    }

    nonisolated func pointOfInterestTemplate(
        _ pointOfInterestTemplate: CPPointOfInterestTemplate,
        didSelectPointOfInterest pointOfInterest: CPPointOfInterest
    ) {
        guard let poi = pointOfInterest.userInfo as? POI else { return }
        Task { @MainActor in
            self.showPOIDetail(poi)
        }
    }
}
