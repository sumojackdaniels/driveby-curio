import SwiftUI
import CoreSwift

// iPhone tour browser.
//
// This is the iPhone-side mirror of the CarPlay Tours tab. It exists because:
//   1. CarPlay guideline 3 says every in-drive flow must be reachable from
//      the CarPlay screen alone, but it does NOT say the iPhone screen has
//      to be useless. Having a working iPhone surface is useful for
//      out-of-vehicle browsing.
//   2. More importantly for milestone 1 — when JD is testing in the iOS
//      Simulator without the CarPlay window enabled, this is the only way to
//      pick a tour and start playback. The CarPlay window can be flaky in
//      the Simulator depending on Xcode version and entitlement state; the
//      iPhone surface is the always-works fallback.
//
// The tour list, the "now playing" banner, and the manual "next stop"
// button mirror the CarPlay surface 1:1 so testing on iPhone is meaningfully
// equivalent to testing on CarPlay.

struct TourBrowserView: View {
    @Environment(TourCatalogStore.self) var catalogStore
    @Environment(TourPlayer.self) var player

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let tour = player.activeTour {
                    NowPlayingBanner(tour: tour)
                }

                List {
                    Section {
                        if catalogStore.isLoading && catalogStore.tours.isEmpty {
                            HStack { ProgressView(); Text("Loading tours…") }
                        } else if catalogStore.tours.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No tours available")
                                    .font(.headline)
                                if let err = catalogStore.lastError {
                                    Text(err)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            ForEach(catalogStore.tours) { tour in
                                TourRow(summary: tour)
                            }
                        }
                    } header: {
                        Text("Curated tours")
                    }

                    Section {
                        CarPlayConnectionView()
                        LocationStatusView()
                    } header: {
                        Text("Status")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("DriveByCurio")
            .task {
                if catalogStore.tours.isEmpty {
                    await catalogStore.loadCatalog()
                }
            }
            .refreshable {
                await catalogStore.loadCatalog()
            }
        }
    }
}

private struct TourRow: View {
    let summary: TourSummary
    @Environment(TourCatalogStore.self) var catalogStore
    @Environment(TourPlayer.self) var player
    @State private var isStarting = false

    var body: some View {
        Button {
            Task {
                isStarting = true
                if let tour = await catalogStore.fetchTour(id: summary.id) {
                    player.startTour(tour)
                }
                isStarting = false
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Image(systemName: "headphones")
                        .foregroundStyle(.white)
                        .font(.title3)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(summary.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Label("\(summary.duration_minutes) min", systemImage: "clock")
                        Label("\(summary.waypoint_count) stops", systemImage: "mappin.and.ellipse")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if isStarting {
                    ProgressView()
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct NowPlayingBanner: View {
    let tour: Tour
    @Environment(TourPlayer.self) var player

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tour.title.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    if let wp = player.currentWaypoint {
                        Text(wp.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text(wp.subject)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    } else {
                        Text("Ready")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                Text("Stop \(player.currentWaypointIndex + 1) of \(tour.waypoints.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack(spacing: 16) {
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                Button {
                    player.manualAdvance()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.18), in: Circle())
                }
                Spacer()
                Button("End", role: .destructive) {
                    player.endTour()
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .padding()
        .background(LinearGradient(
            colors: [.indigo, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
}
