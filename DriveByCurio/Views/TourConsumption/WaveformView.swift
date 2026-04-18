import SwiftUI

// MARK: - Waveform View
//
// Decorative audio waveform visualization matching the wireframe's
// bar-based progress indicator. Uses Canvas for efficient drawing.
//
// NOTE: This is a custom component — no standard SwiftUI equivalent exists
// for audio waveform visualization. Canvas provides GPU-accelerated drawing.

struct WaveformView: View {
    var progress: Double = 0.4
    var barCount: Int = 48
    var playedColor: Color = TourTokens.ink
    var unplayedColor: Color = TourTokens.faint
    var seed: Int = 7

    // Pre-compute amplitudes so the body stays cheap
    private var amplitudes: [Double] {
        (0..<barCount).map { i in
            let s = sin(Double(i + seed) * 12.9898) * 43758.5453
            let r = s - floor(s)
            return 0.25 + 0.75 * abs(sin(Double(i) * 0.4) * 0.5 + r * 0.5)
        }
    }

    var body: some View {
        // Pure SwiftUI — avoids Canvas/Metal stall on fullScreenCover presentation
        HStack(spacing: 2) {
            let playedBars = Int(Double(barCount) * progress)
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(i < playedBars ? playedColor : unplayedColor)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(y: amplitudes[i], anchor: .center)
            }
        }
    }
}
