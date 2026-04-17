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

    var body: some View {
        Canvas { context, size in
            let gap: CGFloat = 2
            let barWidth = (size.width - gap * CGFloat(barCount - 1)) / CGFloat(barCount)
            let playedBars = Int(Double(barCount) * progress)

            for i in 0..<barCount {
                // Pseudo-random height based on seed
                let s = sin(Double(i + seed) * 12.9898) * 43758.5453
                let r = s - floor(s)
                let amplitude = 0.25 + 0.75 * abs(sin(Double(i) * 0.4) * 0.5 + r * 0.5)
                let barHeight = size.height * amplitude
                let x = CGFloat(i) * (barWidth + gap)
                let y = (size.height - barHeight) / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                let color = i < playedBars ? playedColor : unplayedColor
                context.fill(path, with: .color(color))
            }
        }
    }
}
