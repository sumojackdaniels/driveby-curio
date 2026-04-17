import SwiftUI
import MapKit

// Tour detail — shows tour info, map of waypoints, and Start button.

struct WalkingTourDetailView: View {
    let tour: WalkingTour
    @Environment(WalkingTourPlayer.self) var player
    @State private var showPlayback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tour header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(tour.mode.displayName, systemImage: tour.mode.iconName)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())

                        if tour.creatorIsLocal {
                            Label("Local Resident", systemImage: "house.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    Text(tour.title)
                        .font(.title.weight(.bold))

                    Text("by \(tour.creatorName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !tour.description.isEmpty {
                        Text(tour.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        Label("\(tour.waypoints.count) stops", systemImage: "mappin.and.ellipse")
                        Label("~\(tour.estimatedDurationMinutes) min", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Tags
                    if !tour.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(tour.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Map preview
                if !tour.waypoints.isEmpty {
                    WaypointPreviewMap(waypoints: tour.waypoints)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Stops list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stops")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(tour.waypoints.sorted { $0.order < $1.order }) { wp in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 28, height: 28)
                                Text("\(wp.order)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(wp.title)
                                    .font(.subheadline.weight(.medium))
                                if !wp.description.isEmpty {
                                    Text(wp.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Start button
                Button {
                    player.startTour(tour)
                    showPlayback = true
                } label: {
                    Label("Start Tour", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPlayback) {
            WalkingTourPlaybackView(tour: tour)
        }
    }
}

// MARK: - Waypoint Preview Map

struct WaypointPreviewMap: View {
    let waypoints: [WalkingWaypoint]

    var body: some View {
        Map {
            ForEach(waypoints) { wp in
                Annotation(wp.title, coordinate: wp.coordinate) {
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 24, height: 24)
                        Text("\(wp.order)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }

            if waypoints.count >= 2 {
                let coords = waypoints.sorted { $0.order < $1.order }.map(\.coordinate)
                MapPolyline(coordinates: coords)
                    .stroke(.green.opacity(0.6), lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }
}
