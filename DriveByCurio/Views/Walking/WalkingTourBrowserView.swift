import SwiftUI
import CoreSwift

// Walking tour browser — shows pre-authored tours and user-created tours.
// This is the main iPhone surface for walking tours.

struct WalkingTourBrowserView: View {
    @Environment(WalkingTourStore.self) var tourStore
    @Environment(WalkingTourPlayer.self) var player
    @State private var showCreateTour = false

    var body: some View {
        NavigationStack {
            List {
                // Active playback banner
                if let tour = player.activeTour {
                    Section {
                        NavigationLink {
                            WalkingTourPlaybackView(tour: tour)
                        } label: {
                            ActiveTourBanner(tour: tour)
                        }
                    }
                }

                // Authored tours
                if !tourStore.authoredTours.isEmpty {
                    Section("Featured Tours") {
                        ForEach(tourStore.authoredTours) { tour in
                            WalkingTourRow(tour: tour)
                        }
                    }
                }

                // User-created tours
                if !tourStore.userTours.isEmpty {
                    Section("My Tours") {
                        ForEach(tourStore.userTours) { tour in
                            WalkingTourRow(tour: tour)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                tourStore.deleteUserTour(tourId: tourStore.userTours[index].id)
                            }
                        }
                    }
                }

                // Status
                Section {
                    LocationStatusView()
                } header: {
                    Text("Status")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("DriveByCurio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateTour = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateTour) {
                CreateTourView()
            }
        }
    }
}

// MARK: - Tour Row

private struct WalkingTourRow: View {
    let tour: WalkingTour
    @Environment(WalkingTourPlayer.self) var player
    @State private var showPlayback = false

    var body: some View {
        NavigationLink {
            WalkingTourDetailView(tour: tour)
        } label: {
            HStack(spacing: 12) {
                // Mode icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tourGradient)
                    Image(systemName: tour.mode.iconName)
                        .foregroundStyle(.white)
                        .font(.title3)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tour.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(tour.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Label("\(tour.waypoints.count) stops", systemImage: "mappin")
                        Label(tour.mode.displayName, systemImage: tour.mode.iconName)
                        if tour.creatorIsLocal {
                            Label("Local", systemImage: "house.fill")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    private var tourGradient: LinearGradient {
        switch tour.mode {
        case .walking:
            LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .biking:
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .driving:
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Active Tour Banner

private struct ActiveTourBanner: View {
    let tour: WalkingTour
    @Environment(WalkingTourPlayer.self) var player

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: modeIcon)
                    .foregroundStyle(modeColor)
                Text(modeLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(modeColor)
                Spacer()
                Text("Stop \(player.currentWaypointIndex + 1)/\(tour.waypoints.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let wp = player.currentWaypoint {
                Text(wp.title)
                    .font(.subheadline.weight(.semibold))
            }

            Text("Tap to return to tour")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var modeIcon: String {
        switch player.playbackMode {
        case .listening: "headphones"
        case .navInstruction: "location.fill"
        case .compass: "safari"
        case .finished: "checkmark.circle"
        }
    }

    private var modeLabel: String {
        switch player.playbackMode {
        case .listening: "LISTENING"
        case .navInstruction: "DIRECTIONS"
        case .compass: "WALKING"
        case .finished: "COMPLETE"
        }
    }

    private var modeColor: Color {
        switch player.playbackMode {
        case .listening: .green
        case .navInstruction: .orange
        case .compass: .blue
        case .finished: .purple
        }
    }
}
