import SwiftUI

// Root container: hosts the navigation stack AND the persistent docked
// player banner. The banner sits at the bottom of the ZStack so it stays
// on screen across navigation pushes (browser → tour overview).
//
// Owns:
//   - the navigation path binding, so we know whether the user is on the
//     browser (path empty) or inside a tour overview (path has a tour);
//   - the segment-player fullScreenCover state, so the banner can open
//     the full-screen player from the active tour's overview.
//
// The banner is only shown when a tour is actively playing. Before
// playback starts, users tap the Play button on TourOverviewView (next
// to the tour title) to begin — that starts the tour and makes the
// banner appear at the root level.

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
        // Only show when a tour is actively playing. Switching to another
        // tour's overview does NOT change the banner — it keeps showing
        // the playing tour until the user taps Play on the new one.
        if let tour = player.activeTour, player.hasStarted {
            let sortedStops = tour.sortedStops
            if !sortedStops.isEmpty {
                let stopIdx = min(max(0, player.currentStopIndex), sortedStops.count - 1)
                let isInTransit = player.playbackMode == .compass

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
                    let atStop = player.playbackMode == .listening && !player.isPlaying

                    DockedPlayerBanner(
                        tour: tour,
                        currentStopIndex: stopIdx,
                        atStop: atStop,
                        onBannerTap: { handleBannerTap(tour: tour, stopIdx: stopIdx) },
                        onPlayPauseTap: { player.togglePlayPause() }
                    )
                }
            }
        }
    }

    private func handleBannerTap(tour: WalkingTour, stopIdx: Int) {
        if path.last?.id == tour.id {
            // Already on the active tour's overview — open the segment player.
            let stop = tour.sortedStops[stopIdx]
            if let first = stop.segments.first {
                selectedStopIndex = stopIdx
                selectedSegment = first
            }
        } else {
            // User is elsewhere (browser or a different tour's overview) —
            // jump to the playing tour's overview.
            path = [tour]
        }
    }
}
