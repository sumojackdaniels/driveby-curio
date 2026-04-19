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
            if let tour = player.activeTour {
                SegmentPlayerView(
                    tour: tour,
                    stopIndex: selectedStopIndex,
                    segment: segment,
                    progress: player.audioDuration > 0
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

    @ViewBuilder
    private var dockedBanner: some View {
        if let activeTour = player.activeTour {
            let sortedStops = activeTour.sortedStops
            if !sortedStops.isEmpty {
                let stopIdx = min(max(0, player.currentStopIndex), sortedStops.count - 1)
                let paths = activeTour.paths
                let isInTransit = player.playbackMode == .compass

                if isInTransit {
                    let nextIndex = min(player.currentStopIndex + 1, sortedStops.count - 1)
                    let nextStop = sortedStops[nextIndex]
                    let distanceFeet = player.currentStopIndex < paths.count
                        ? paths[player.currentStopIndex].distanceFeet
                        : Int(player.distanceToNextStop * 3.28084)

                    DockedPlayerBanner(
                        tour: activeTour,
                        currentStopIndex: player.currentStopIndex,
                        onBannerTap: { player.openMapsToNextStop() },
                        navigateAddress: nextStop.address,
                        navigateDistanceFeet: distanceFeet
                    )
                } else {
                    let atStop = !player.hasStarted
                        || (player.playbackMode == .listening && !player.isPlaying)

                    DockedPlayerBanner(
                        tour: activeTour,
                        currentStopIndex: stopIdx,
                        atStop: atStop,
                        onBannerTap: { handleBannerTap(tour: activeTour, stopIdx: stopIdx) },
                        onPlayPauseTap: { handlePlayPauseTap(tour: activeTour) }
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
        if !player.hasStarted {
            player.startTour(tour)
        } else {
            player.togglePlayPause()
        }
    }
}
