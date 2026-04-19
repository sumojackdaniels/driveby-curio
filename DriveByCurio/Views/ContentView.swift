import SwiftUI

// Root container: hosts the navigation stack AND the persistent docked
// player banner. The banner sits at the bottom of the ZStack so it stays
// on screen across navigation pushes (browser → tour overview).
//
// Owns:
//   - the navigation path binding, so we know whether the user is on the
//     browser (path empty) or inside a tour overview (path has a tour),
//     and we can push when the banner is tapped from the browser;
//   - the segment-player fullScreenCover state, so the banner can open the
//     full-screen player from either context.

struct ContentView: View {
    @Environment(WalkingTourPlayer.self) var player
    @State private var path: [WalkingTour] = []
    @State private var selectedSegment: TourSegment?
    @State private var selectedStopIndex: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            WalkingTourBrowserView(path: $path)

            dockedBanner
        }
        .fullScreenCover(item: $selectedSegment) { segment in
            if let tour = bannerTour {
                SegmentPlayerView(
                    tour: tour,
                    stopIndex: selectedStopIndex,
                    segment: segment,
                    progress: bannerIsActivePlayer && player.audioDuration > 0
                        ? player.audioCurrentTime / player.audioDuration
                        : 0
                )
                // fullScreenCover creates a separate presentation tree —
                // @Environment objects from the parent are NOT inherited.
                .environment(player)
            }
        }
    }

    // MARK: - Docked Banner

    /// Which tour should the banner represent?
    /// - If the user is viewing a tour overview (path has an entry), use that
    ///   tour — the banner acts as the "start tour" affordance on the overview
    ///   even before playback begins.
    /// - Otherwise, use the active tour (the banner trails behind the user
    ///   while they browse other tours).
    private var bannerTour: WalkingTour? {
        path.last ?? player.activeTour
    }

    /// Whether the banner is representing the actively-playing tour, vs a
    /// tour the user is just viewing. Controls which state + callbacks apply.
    private var bannerIsActivePlayer: Bool {
        guard let bt = bannerTour else { return false }
        return player.activeTour?.id == bt.id && player.hasStarted
    }

    @ViewBuilder
    private var dockedBanner: some View {
        if let tour = bannerTour {
            let sortedStops = tour.sortedStops
            if !sortedStops.isEmpty {
                let stopIdx = min(max(0, bannerIsActivePlayer ? player.currentStopIndex : 0), sortedStops.count - 1)
                let isInTransit = bannerIsActivePlayer && player.playbackMode == .compass

                if isInTransit {
                    let paths = tour.paths
                    let nextIndex = min(player.currentStopIndex + 1, sortedStops.count - 1)
                    let nextStop = sortedStops[nextIndex]
                    let distanceFeet = player.currentStopIndex < paths.count
                        ? paths[player.currentStopIndex].distanceFeet
                        : Int(player.distanceToNextStop * 3.28084)

                    DockedPlayerBanner(
                        tour: tour,
                        currentStopIndex: player.currentStopIndex,
                        onBannerTap: { player.openMapsToNextStop() },
                        navigateAddress: nextStop.address,
                        navigateDistanceFeet: distanceFeet
                    )
                } else {
                    let atStop = !bannerIsActivePlayer
                        || (player.playbackMode == .listening && !player.isPlaying)

                    DockedPlayerBanner(
                        tour: tour,
                        currentStopIndex: stopIdx,
                        atStop: atStop,
                        onBannerTap: { handleBannerTap(tour: tour, stopIdx: stopIdx) },
                        onPlayPauseTap: { handlePlayPauseTap(tour: tour) }
                    )
                }
            }
        }
    }

    private func handleBannerTap(tour: WalkingTour, stopIdx: Int) {
        if path.isEmpty {
            // On browser — push the tour overview.
            path.append(tour)
        } else {
            // Already inside a tour overview — open the segment player.
            let stop = tour.sortedStops[stopIdx]
            if let first = stop.segments.first {
                selectedStopIndex = stopIdx
                selectedSegment = first
            }
        }
    }

    private func handlePlayPauseTap(tour: WalkingTour) {
        if player.activeTour?.id != tour.id || !player.hasStarted {
            player.startTour(tour)
        } else {
            player.togglePlayPause()
        }
    }
}
