import CarPlay
import CoreLocation
import CoreSwift
import UIKit

// CarPlay scene delegate — Audio category implementation.
//
// Template structure (see specs/CARPLAY-CONSTRAINTS.md for the allow-list):
//
//   CPTabBarTemplate (root)
//     ├── Tours tab            → CPListTemplate of curated tours
//     │     └── on tap         → CPNowPlayingTemplate.shared() (tour starts)
//     │           └── Playing Next button → CPListTemplate (upcoming queue)
//     └── (placeholder) Live tab → an alert template explaining that live
//                                  mode is being rebuilt; we keep the tab so
//                                  the navigation shape matches PRODUCT.md
//                                  even though milestone 1 ships tours only.
//
// Audio session is NOT activated on connect — only when the user explicitly
// taps a tour to start it (TourPlayer.startTour). This is the audio-citizen
// rule from the CarPlay developer guide.

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    private var templateApplicationScene: CPTemplateApplicationScene?

    static var shared: CarPlaySceneDelegate?
    @MainActor static var isConnected = false

    private var tourCatalogStore: TourCatalogStore { AppState.shared.tourCatalogStore }
    private var tourPlayer: TourPlayer { AppState.shared.tourPlayer }
    private var locationService: LocationService { AppState.shared.locationService }

    private var toursListTemplate: CPListTemplate?

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
            startLocationObservation()
            await tourCatalogStore.loadCatalog()
            self.refreshToursList()
            configureNowPlayingTemplate()
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        Task { @MainActor in
            Self.isConnected = false
            locationService.stopUpdating()
        }
        self.interfaceController = nil
        self.templateApplicationScene = nil
        Self.shared = nil
    }

    // MARK: - Tab Bar

    @MainActor
    private func setupTabBar() {
        let toursTemplate = createToursListTemplate()
        self.toursListTemplate = toursTemplate

        let liveTemplate = createLivePlaceholderTemplate()

        let tabBar = CPTabBarTemplate(templates: [toursTemplate, liveTemplate])
        interfaceController?.setRootTemplate(tabBar, animated: false)
    }

    // MARK: - Tours list

    @MainActor
    private func createToursListTemplate() -> CPListTemplate {
        let template = CPListTemplate(title: "Tours", sections: [])
        template.tabTitle = "Tours"
        template.tabImage = UIImage(systemName: "headphones")
        template.emptyViewTitleVariants = ["Loading tours…"]
        template.emptyViewSubtitleVariants = ["Curated drives load from the backend on connect."]
        return template
    }

    @MainActor
    private func refreshToursList() {
        guard let template = toursListTemplate else { return }

        let items: [CPListItem] = tourCatalogStore.tours.map { summary in
            let item = CPListItem(
                text: summary.title,
                detailText: "\(summary.region) · \(summary.duration_minutes) min · \(summary.waypoint_count) stops"
            )
            item.handler = { [weak self] _, completion in
                Task { @MainActor in
                    await self?.startTour(id: summary.id)
                    completion()
                }
            }
            return item
        }

        let section = CPListSection(items: items, header: "Curated tours", sectionIndexTitle: nil)
        template.updateSections([section])
    }

    @MainActor
    private func startTour(id: String) async {
        guard let tour = await tourCatalogStore.fetchTour(id: id) else { return }
        tourPlayer.startTour(tour)

        // Push the system Now Playing template on top of the current stack
        // so the driver immediately sees the playback surface.
        let nowPlaying = CPNowPlayingTemplate.shared
        interfaceController?.pushTemplate(nowPlaying, animated: true)
    }

    // MARK: - Live placeholder (Mode 2 — coming back later)

    @MainActor
    private func createLivePlaceholderTemplate() -> CPListTemplate {
        let template = CPListTemplate(title: "Live", sections: [])
        template.tabTitle = "Live"
        template.tabImage = UIImage(systemName: "antenna.radiowaves.left.and.right")
        template.emptyViewTitleVariants = ["Live mode is coming"]
        template.emptyViewSubtitleVariants = [
            "On-the-fly contextual narration for any drive — under redesign for the Audio category."
        ]
        return template
    }

    // MARK: - Now Playing template configuration

    @MainActor
    private func configureNowPlayingTemplate() {
        let np = CPNowPlayingTemplate.shared
        np.isUpNextButtonEnabled = true
        np.upNextTitle = "Playing Next"
        np.add(self)

        // Custom buttons: the system handles play/pause and next-track via
        // MPRemoteCommandCenter (configured in TourPlayer). We don't add
        // bespoke CarPlay-only buttons in milestone 1.
    }

    @MainActor
    private func showUpNextList() {
        let upcoming = tourPlayer.upcomingWaypoints
        let items: [CPListItem] = upcoming.map { wp in
            let item = CPListItem(text: wp.title, detailText: wp.subject)
            item.handler = { _, completion in completion() }
            return item
        }
        let section = CPListSection(items: items, header: "Upcoming stops", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Playing Next", sections: [section])
        interfaceController?.pushTemplate(template, animated: true)
    }

    // MARK: - Location observation → trigger-circle progression

    private func startLocationObservation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let location = self.locationService.currentLocation else { return }
                self.tourPlayer.onLocationUpdate(location)
            }
        }
    }
}

// MARK: - CPNowPlayingTemplateObserver

extension CarPlaySceneDelegate: CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task { @MainActor in
            self.showUpNextList()
        }
    }
}
