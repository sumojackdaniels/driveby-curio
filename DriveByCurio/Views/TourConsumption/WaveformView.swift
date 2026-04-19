import SwiftUI

// MARK: - Waveform View
//
// Decorative audio waveform visualization with optional tap/drag-to-seek.
// Bars are RoundedRectangles with deterministic per-bar amplitude scaling
// (cached in init) so rendering stays cheap and we avoid the Canvas/Metal
// stall inside fullScreenCover.
//
// Interaction model:
//   - Tap a bar:       finger down + up → commit that fraction via onSeek.
//   - Drag:            bars highlight/unhighlight under the finger but the
//                      actual playback position does NOT change until
//                      release.
//   - Release:         commit the final fraction via onSeek.
//
// When `onSeek` is nil the view is non-interactive (pure decoration).

struct WaveformView: View {
    var progress: Double
    var barCount: Int
    var playedColor: Color
    var unplayedColor: Color
    var onSeek: ((Double) -> Void)?
    private let amplitudes: [Double]

    @GestureState private var dragFraction: Double? = nil

    init(
        progress: Double = 0.4,
        barCount: Int = 48,
        playedColor: Color = TourTokens.ink,
        unplayedColor: Color = TourTokens.faint,
        seed: Int = 7,
        onSeek: ((Double) -> Void)? = nil
    ) {
        self.progress = progress
        self.barCount = barCount
        self.playedColor = playedColor
        self.unplayedColor = unplayedColor
        self.onSeek = onSeek
        self.amplitudes = (0..<barCount).map { i in
            let s = sin(Double(i + seed) * 12.9898) * 43758.5453
            let r = s - floor(s)
            return 0.25 + 0.75 * abs(sin(Double(i) * 0.4) * 0.5 + r * 0.5)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let displayedProgress = dragFraction ?? progress
            let playedBars = Int(Double(barCount) * displayedProgress)

            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(i < playedBars ? playedColor : unplayedColor)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(y: amplitudes[i], anchor: .center)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                onSeek == nil ? nil : scrubGesture(width: geo.size.width)
            )
        }
    }

    // MARK: - Gesture

    private func scrubGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragFraction) { value, state, _ in
                state = Self.fraction(forX: value.location.x, width: width)
            }
            .onEnded { value in
                let final = Self.fraction(forX: value.location.x, width: width)
                onSeek?(final)
            }
    }

    // MARK: - Pure helpers (testable)

    /// Map a finger x-coordinate to a fractional position in [0, 1].
    /// Clamps out-of-range x values and defends against zero/negative widths.
    static func fraction(forX x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        let clamped = min(max(x, 0), width)
        return Double(clamped / width)
    }
}
