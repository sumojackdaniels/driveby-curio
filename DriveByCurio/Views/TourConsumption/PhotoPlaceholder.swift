import SwiftUI

// MARK: - Photo Placeholder
//
// Striped placeholder matching the wireframe's "[photo]" convention.
// Will be replaced with real images once tour photos are available.

struct PhotoPlaceholder: View {
    var label: String = "photo"
    var height: CGFloat = 140
    var cornerRadius: CGFloat = 14
    var imageName: String? = nil

    var body: some View {
        ZStack {
            if let imageName, let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Solid placeholder background (avoids Canvas/Metal rendering stalls)
                Color(.systemGray6)

                // Label
                Text("[\(label)]")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .tracking(0.3)
            }
        }
        .frame(height: height)
        .clipped()
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
