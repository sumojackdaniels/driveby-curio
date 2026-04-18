import SwiftUI

// MARK: - Waveform View
//
// Decorative audio waveform visualization matching the wireframe's
// bar-based progress indicator. Bars are RoundedRectangles with
// deterministic per-bar amplitude scaling — keeps rendering cheap
// and avoids the Canvas/Metal stall we hit on fullScreenCover.

struct WaveformView: View {
    var progress: Double
    var barCount: Int
    var playedColor: Color
    var unplayedColor: Color
    private let amplitudes: [Double]

    init(
        progress: Double = 0.4,
        barCount: Int = 48,
        playedColor: Color = TourTokens.ink,
        unplayedColor: Color = TourTokens.faint,
        seed: Int = 7
    ) {
        self.progress = progress
        self.barCount = barCount
        self.playedColor = playedColor
        self.unplayedColor = unplayedColor
        self.amplitudes = (0..<barCount).map { i in
            let s = sin(Double(i + seed) * 12.9898) * 43758.5453
            let r = s - floor(s)
            return 0.25 + 0.75 * abs(sin(Double(i) * 0.4) * 0.5 + r * 0.5)
        }
    }

    var body: some View {
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
