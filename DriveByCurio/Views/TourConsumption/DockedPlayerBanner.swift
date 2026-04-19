import SwiftUI

// MARK: - Docked Player Banner
//
// Full-width banner pinned to the bottom of the app (root-level in
// ContentView), so it persists across navigation pushes. Three states
// matching the wireframe:
//   1. "At a stop" — shows stop title, "You are at {address}", play button
//   2. "Playing"   — shows tour title eyebrow, segment title, stop info, pause button
//   3. "Navigate"  — ember background, distance away, "Navigate there" CTA
//
// The caller provides two tap callbacks:
//   - onBannerTap: user taps anywhere on the banner (except the play button)
//   - onPlayPauseTap: user taps the circular play/pause button
//
// The banner's background extends into the bottom safe area so the home
// indicator sits on top of the dark material. Content stays padded above
// the safe area.

struct DockedPlayerBanner: View {
    let tour: WalkingTour
    let currentStopIndex: Int
    var currentSegmentIndex: Int = 0
    var atStop: Bool = false

    // Callbacks
    var onBannerTap: (() -> Void)? = nil
    var onPlayPauseTap: (() -> Void)? = nil

    // Navigate state — when set, shows the ember navigate banner instead
    var navigateAddress: String? = nil
    var navigateDistanceFeet: Int? = nil

    private var currentStop: TourStop? {
        let sorted = tour.sortedStops
        guard (0..<sorted.count).contains(currentStopIndex) else { return nil }
        return sorted[currentStopIndex]
    }

    private var currentSegment: TourSegment? {
        guard let stop = currentStop,
              (0..<stop.segments.count).contains(currentSegmentIndex) else { return nil }
        return stop.segments[currentSegmentIndex]
    }

    var body: some View {
        if let address = navigateAddress, let distance = navigateDistanceFeet {
            navigateBanner(address: address, distanceFeet: distance)
        } else if let stop = currentStop {
            playerBanner(for: stop)
        }
    }

    // MARK: - Player Banner

    private func playerBanner(for currentStop: TourStop) -> some View {
        VStack(spacing: 0) {
            progressBar

            // Content row — whole row is the banner's tap target
            HStack(spacing: 12) {
                artworkTile

                // Text column — fixed height so state changes don't shift pixels
                VStack(alignment: .leading, spacing: 2) {
                    eyebrow
                    title(for: currentStop)
                    subInfoRow(for: currentStop)
                }
                .frame(height: Self.contentHeight, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Play/pause button — its own hit target so it doesn't
                // trigger onBannerTap.
                Button {
                    onPlayPauseTap?()
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: playPauseIconName)
                                .font(.system(size: 12))
                                .foregroundStyle(.black)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(playPauseAccessibilityLabel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { onBannerTap?() }
        }
        .background {
            Rectangle()
                .fill(Color.black.opacity(0.88))
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Player Banner subviews

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.12))
            Rectangle()
                .fill(TourTokens.moss)
                .scaleEffect(
                    x: atStop ? 0 : min(0.92, Double(currentStopIndex) / Double(max(1, tour.totalStops))),
                    y: 1,
                    anchor: .leading
                )
        }
        .frame(height: 2)
    }

    private var artworkTile: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray4))
            .frame(width: 44, height: 44)
            .overlay(
                Text("[art]")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            )
    }

    private var eyebrow: some View {
        Text(tour.title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.55))
            .lineLimit(1)
    }

    private func title(for currentStop: TourStop) -> some View {
        Text(atStop ? currentStop.title : (currentSegment?.title ?? currentStop.title))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .lineLimit(1)
    }

    @ViewBuilder
    private func subInfoRow(for currentStop: TourStop) -> some View {
        // Always renders in a fixed-height container so switching between
        // at-stop and playing states doesn't shift the layout.
        if atStop {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(TourTokens.moss)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(TourTokens.moss.opacity(0.35))
                        .frame(width: 14, height: 14)
                }
                .frame(width: 14, height: 14)

                Text("You are at \(currentStop.address)")
                    .font(.caption2)
                    .foregroundStyle(TourTokens.moss)
                    .lineLimit(1)
            }
        } else if currentSegment != nil {
            Text("Stop \(currentStop.order) · \(currentStop.title)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
        } else {
            // Keeps vertical metrics when we have no segment info to show.
            Text(" ")
                .font(.caption2)
                .lineLimit(1)
        }
    }

    // MARK: - Computed helpers

    private var playPauseIconName: String {
        atStop ? "play.fill" : "pause.fill"
    }

    private var playPauseAccessibilityLabel: String {
        atStop ? "Play" : "Pause"
    }

    // Fixed height for the text column — covers eyebrow (~12pt) + title
    // (~18pt) + sub-info (14pt pulse row or caption2), so the banner
    // doesn't shift between at-stop and playing states.
    private static let contentHeight: CGFloat = 44

    // MARK: - Navigate Banner

    private func navigateBanner(address: String, distanceFeet: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<28, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(width: 6, height: 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 2)
            .background(.white.opacity(0.18))
            .clipped()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("You are ")
                            .foregroundStyle(.white.opacity(0.85))
                        Text("\(distanceFeet) feet away")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .font(.subheadline)

                    Text("Head to \(address)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    onBannerTap?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 10))
                        Text("Navigate there")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(TourTokens.ember)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background {
            Rectangle()
                .fill(TourTokens.ember)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
