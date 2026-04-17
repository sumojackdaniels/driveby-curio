import SwiftUI

// MARK: - Segment Player View
//
// Full-screen editorial segment player. Matches wireframe screen 04.
// Presented as a sheet/fullScreenCover from the tour overview.
//
// Layout:
// - Top bar: dismiss chevron, stop label, spacer
// - Segment kind + title (serif)
// - Descriptive quote (serif italic)
// - Photo cluster (two tiled placeholders)
// - Waveform progress bar (custom Canvas — see WaveformView.swift)
// - Elapsed / remaining time
// - Centered play/pause button
//
// Standard SwiftUI used for everything except WaveformView (custom Canvas).

struct SegmentPlayerView: View {
    let tour: WalkingTour
    let stopIndex: Int
    let segment: TourSegment
    var progress: Double = 0.5

    @Environment(\.dismiss) var dismiss
    @Environment(WalkingTourPlayer.self) var player

    private var stop: WalkingWaypoint {
        tour.sortedStops[stopIndex]
    }

    private var isPlayerActive: Bool {
        player.activeTour?.id == tour.id
    }

    private var currentProgress: Double {
        guard isPlayerActive, player.audioDuration > 0 else { return progress }
        return player.audioCurrentTime / player.audioDuration
    }

    private var elapsed: TimeInterval {
        if isPlayerActive { return player.audioCurrentTime }
        return Double(segment.durationMinutes * 60) * progress
    }

    private var remaining: TimeInterval {
        if isPlayerActive { return max(0, player.audioDuration - player.audioCurrentTime) }
        return Double(segment.durationMinutes * 60) * (1 - progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Segment meta + title
                    segmentHeader
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    // Photo cluster
                    PhotoCluster(label: stop.title)
                        .padding(.horizontal, 28)
                        .padding(.top, 18)
                }
            }

            Spacer()

            // Bottom controls
            bottomControls
        }
        .background(Color(red: 0.984, green: 0.976, blue: 0.957)) // #fbf9f4
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Dismiss
            Button { dismiss() } label: {
                Circle()
                    .fill(.clear)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TourTokens.ink)
                    )
            }
            .accessibilityLabel("Dismiss")

            Spacer()

            // Stop label
            HStack(spacing: 6) {
                Text("Stop \(stop.order)")
                    .foregroundStyle(TourTokens.muted)
                Text("·")
                    .foregroundStyle(TourTokens.muted)
                Text(stop.title)
                    .foregroundStyle(TourTokens.ink)
            }
            .font(.caption)

            Spacer()

            // Balance spacer
            Color.clear
                .frame(width: 34, height: 34)
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }

    // MARK: - Segment Header

    private var segmentHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Kind label with icon
            HStack(spacing: 6) {
                Image(systemName: segment.kind.iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(TourTokens.moss)
                Text(segment.kind.label.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .tracking(0.6)
                    .foregroundStyle(TourTokens.moss)
            }

            // Title
            Text(segment.title)
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(TourTokens.ink)
                .lineSpacing(2)
                .padding(.top, 12)

            // Description quote
            if !segment.description.isEmpty {
                Text("\"\(segment.description)\"")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(TourTokens.ink2)
                    .lineSpacing(4)
                    .padding(.top, 14)
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Waveform
            WaveformView(
                progress: currentProgress,
                barCount: 52,
                playedColor: TourTokens.ink,
                unplayedColor: TourTokens.faint,
                seed: stopIndex + segment.id.hashValue % 100
            )
            .frame(height: 40)

            // Time labels
            HStack {
                Text(formatTime(elapsed))
                Spacer()
                Text("-\(formatTime(remaining))")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(TourTokens.muted)
            .padding(.top, 6)

            // Play/pause button
            Button {
                if isPlayerActive {
                    player.togglePlayPause()
                }
            } label: {
                Circle()
                    .fill(TourTokens.ink)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    .overlay(
                        Image(systemName: isPlayerActive && player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    )
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
