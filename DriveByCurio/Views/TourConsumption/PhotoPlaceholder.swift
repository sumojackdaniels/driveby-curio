import SwiftUI

// MARK: - Photo Placeholder
//
// Striped placeholder matching the wireframe's "[photo]" convention.
// Will be replaced with real images once tour photos are available.

struct PhotoPlaceholder: View {
    var label: String = "photo"
    var height: CGFloat = 140
    var cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            // Striped background
            Canvas { context, size in
                let stripeWidth: CGFloat = 8
                let totalStripes = Int(ceil((size.width + size.height) / stripeWidth))
                for i in 0..<totalStripes {
                    let x = CGFloat(i) * stripeWidth * 2
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                    path.addLine(to: CGPoint(x: x - size.height + stripeWidth, y: size.height))
                    path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
                    path.closeSubpath()
                    context.fill(path, with: .color(Color(.systemGray5)))
                }
            }
            .background(Color(.systemGray6))

            // Label
            Text("[\(label)]")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.6))
                .tracking(0.3)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Photo Cluster
//
// Two tiled placeholder images from the current stop.
// Matches the wireframe's "From this stop" treatment.

struct PhotoCluster: View {
    var label: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FROM THIS STOP")
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(0.6)
                .foregroundStyle(TourTokens.muted)

            HStack(spacing: 6) {
                PhotoPlaceholder(label: "img 1", height: 100, cornerRadius: 6)
                    .frame(maxWidth: .infinity)
                PhotoPlaceholder(label: "img 2", height: 100, cornerRadius: 6)
                    .frame(maxWidth: .infinity)
                    .frame(maxWidth: 120)
            }
        }
    }
}
