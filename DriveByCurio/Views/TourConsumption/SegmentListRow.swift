import SwiftUI

// MARK: - Segment List Row
//
// A single segment within an expanded stop. Shows play button, kind label,
// duration, and title. Uses standard SwiftUI components:
// - HStack/VStack for layout
// - Circle + Image for the play button
// - Standard Text styling
//
// The active segment gets a highlighted card treatment with border.
// The playing state swaps the play triangle for a pause icon.

struct SegmentListRow: View {
    let segment: TourSegment
    var isActive: Bool = false
    var isPlaying: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Play/pause button
            playButton

            // Content
            VStack(alignment: .leading, spacing: 2) {
                // Kind label + duration
                HStack(spacing: 8) {
                    Text(segment.kind.label.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .tracking(0.4)
                        .foregroundStyle(TourTokens.moss)

                    Text("· \(segment.durationMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(TourTokens.muted)
                }

                // Title
                Text(segment.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(TourTokens.ink)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color(.systemBackground) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isActive ? TourTokens.faint : .clear, lineWidth: 1)
        )
    }

    private var playButton: some View {
        ZStack {
            Circle()
                .fill(isActive ? TourTokens.ink : .clear)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isActive ? .clear : TourTokens.faint,
                            lineWidth: 1.2
                        )
                )

            if isPlaying && isActive {
                // Pause icon
                Image(systemName: "pause.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
            } else {
                // Play triangle
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isActive ? .white : TourTokens.ink)
            }
        }
    }
}
