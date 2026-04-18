import SwiftUI

// MARK: - Docked Player Banner
//
// Full-width banner pinned to the bottom of the tour overview.
// Three states matching the wireframe:
//   1. "At a stop" — shows stop title, "You are at {address}", play button
//   2. "Playing"   — shows tour title eyebrow, segment title, stop info, pause button
//   3. "Navigate"  — ember background, distance away, "Navigate there" CTA

struct DockedPlayerBanner: View {
    let tour: WalkingTour
    let currentStopIndex: Int
    var currentSegmentIndex: Int = 0
    var atStop: Bool = false

    // Navigate state — when set, shows the ember navigate banner instead
    var navigateAddress: String? = nil
    var navigateDistanceFeet: Int? = nil

    private var currentStop: TourStop {
        tour.sortedStops[currentStopIndex]
    }

    private var currentSegment: TourSegment? {
        let segments = currentStop.segments
        guard currentSegmentIndex < segments.count else { return nil }
        return segments[currentSegmentIndex]
    }

    var body: some View {
        if let address = navigateAddress, let distance = navigateDistanceFeet {
            navigateBanner(address: address, distanceFeet: distance)
        } else {
            playerBanner
        }
    }

    // MARK: - Player Banner

    private var playerBanner: some View {
        VStack(spacing: 0) {
            // Progress bar — no GeometryReader, uses scaleEffect for sizing
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

            // Content
            HStack(spacing: 12) {
                // Artwork placeholder
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray4))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("[art]")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    )

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    // Tour title eyebrow
                    Text(tour.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)

                    // Stop/segment title
                    Text(atStop ? currentStop.title : (currentSegment?.title ?? currentStop.title))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Sub-info
                    if atStop {
                        // "You are at {address}" with green dot
                        HStack(spacing: 6) {
                            // Pulse dot
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
                        .padding(.top, 1)
                    } else if currentSegment != nil {
                        Text("Stop \(currentStop.order) · \(currentStop.title)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Play/pause button
                Circle()
                    .fill(.white)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: atStop ? "play.fill" : "pause.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.black)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .background(Color.black.opacity(0.88))
    }

    // MARK: - Navigate Banner

    private func navigateBanner(address: String, distanceFeet: Int) -> some View {
        VStack(spacing: 0) {
            // Striped progress bar — fixed stripe count, no GeometryReader
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

            // Content
            HStack(spacing: 12) {
                // Text
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

                // Navigate CTA
                Button(action: {}) {
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(TourTokens.ember)
    }
}
