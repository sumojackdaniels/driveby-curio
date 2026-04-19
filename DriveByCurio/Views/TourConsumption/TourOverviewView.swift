import SwiftUI
import MapKit

// MARK: - Tour Overview View
//
// The main tour consumption screen. Shows the tour hero, author info,
// a scrollable timeline of stops, and a docked player banner.
//
// Corresponds to wireframe screens 01a (at stop), 02 (expanded), 03 (in transit).

struct TourOverviewView: View {
    let tour: WalkingTour
    @Environment(WalkingTourPlayer.self) var player
    @Environment(\.dismiss) var dismiss

    // Tour state
    @State private var expandedStopIndex: Int? = nil

    // Derived state
    private var isPlayerActive: Bool { player.activeTour?.id == tour.id }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero — only this section extends into the top safe area
                heroSection
                    .ignoresSafeArea(edges: .top)

                // Author
                authorSection

                // Quote
                quoteSection

                // Route header
                routeHeader

                // Stops timeline
                stopsTimeline

                // Bottom padding for the root-level docked banner
                Spacer()
                    .frame(height: 120)
            }
        }
        // Do NOT apply .ignoresSafeArea to the outer scroll view — it causes
        // a layout deadlock on NavigationStack push. Scope it to heroSection.
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Photo
            PhotoPlaceholder(
                label: "\(tour.title) cover",
                height: TourTokens.heroHeight,
                cornerRadius: 0,
                imageName: tour.coverImageName
            )

            // Gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.28), location: 0),
                    .init(color: .clear, location: 0.4),
                    .init(color: .black.opacity(0.78), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay — pinned to bottom-leading
            VStack(alignment: .leading, spacing: 0) {
                // Title
                Text(tour.title)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)

                // Meta line: walk · bike · distance
                metaLine
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)

            // Back button — pinned to top-left
            VStack {
                HStack {
                    backButton
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.leading, 12)

                Spacer()
            }
        }
        .frame(height: TourTokens.heroHeight)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Circle()
                .fill(.black.opacity(0.35))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
        .accessibilityLabel("Back")
    }

    private var metaLine: some View {
        HStack(spacing: 14) {
            // Walk time
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 11))
                Text("\(tour.totalWalkMinutes)m")
            }

            // Bike time
            HStack(spacing: 6) {
                Image(systemName: "bicycle")
                    .font(.system(size: 11))
                Text("\(tour.totalBikeMinutes)m")
            }

            Text("·")
                .opacity(0.75)

            // Distance + elevation sparkline
            HStack(spacing: 6) {
                Text(String(format: "%.1f mi", tour.totalDistanceMiles))
                    .opacity(0.9)

                // Elevation sparkline (hill shape)
                ElevationSparkline()
                    .frame(width: 26, height: 12)
                    .opacity(0.8)
            }
        }
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundStyle(.white)
    }

    // MARK: - Author Section

    private var authorSection: some View {
        HStack(spacing: 10) {
            // Avatar
            Circle()
                .fill(TourTokens.mossSoft)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(tour.author.initials)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(TourTokens.moss)
                )

            // Name + role
            VStack(alignment: .leading, spacing: 1) {
                Text("with \(tour.author.name)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(tour.author.role)
                    .font(.caption)
                    .foregroundStyle(TourTokens.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.horizontal, TourTokens.horizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        Text("\"\(tour.coverQuote)\"")
            .font(.system(size: 17, weight: .regular, design: .serif))
            .foregroundStyle(TourTokens.ink2)
            .lineSpacing(4)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }

    // MARK: - Route Header

    private var routeHeader: some View {
        Text("The route")
            .font(.title3)
            .fontWeight(.bold)
            .padding(.horizontal, TourTokens.horizontalPadding)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }

    // MARK: - Stops Timeline

    private var stopsTimeline: some View {
        let sortedStops = tour.sortedStops
        let paths = tour.paths
        let playerStopIndex = isPlayerActive ? player.currentStopIndex : -1
        let isInTransit = isPlayerActive && player.playbackMode == .compass
        let transitFromIndex = isInTransit ? playerStopIndex : -1

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                let state = stopState(
                    index: index,
                    playerStopIndex: playerStopIndex,
                    transitFromIndex: transitFromIndex
                )
                let path = index < paths.count ? paths[index] : nil

                StopTimelineRow(
                    stop: stop,
                    index: index,
                    totalStops: sortedStops.count,
                    segments: stop.segments,
                    stopState: state,
                    isExpanded: expandedStopIndex == index,
                    activeSegmentIndex: 0,
                    isPlaying: isPlayerActive && playerStopIndex == index && player.isPlaying,
                    pathToNext: path,
                    isTransitFromHere: transitFromIndex == index
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if expandedStopIndex == index {
                            expandedStopIndex = nil
                        } else {
                            expandedStopIndex = index
                        }
                    }
                }
            }
        }
        .padding(.horizontal, TourTokens.horizontalPadding)
    }

    private func stopState(
        index: Int,
        playerStopIndex: Int,
        transitFromIndex: Int
    ) -> StopTimelineRow.StopState {
        StopTimelineRow.StopState.resolve(
            index: index,
            isPlayerActive: isPlayerActive,
            playerStopIndex: playerStopIndex,
            transitFromIndex: transitFromIndex,
            playbackMode: player.playbackMode,
            isPlaying: player.isPlaying,
            hasStarted: player.hasStarted
        )
    }

}

// MARK: - Elevation Sparkline

struct ElevationSparkline: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 1, y: 12))
            path.addLine(to: CGPoint(x: 13, y: 2))
            path.addLine(to: CGPoint(x: 25, y: 12))
        }
        .stroke(.white, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
    }
}
