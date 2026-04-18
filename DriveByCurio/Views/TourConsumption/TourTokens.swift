import SwiftUI

// MARK: - Design Tokens
//
// Matches the wireframe design system: SF Pro, iOS system greys,
// moss green accent, ember orange for alerts/navigation.

enum TourTokens {
    // MARK: Colors
    static let moss = Color(red: 0.30, green: 0.50, blue: 0.28)
    static let mossSoft = Color(red: 0.87, green: 0.93, blue: 0.87) // moss at ~12% on white
    static let ember = Color(red: 0.72, green: 0.33, blue: 0.18) // #B8552E

    static let ink = Color.primary
    static let ink2 = Color(.secondaryLabel)
    static let muted = Color(.tertiaryLabel)
    static let faint = Color(.separator)
    static let hairline = Color(.separator).opacity(0.5)
    static let cardBackground = Color(.systemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)

    // MARK: Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let heroHeight: CGFloat = 280
    static let bannerHeight: CGFloat = 90

    // MARK: Typography helpers

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .tracking(0.6)
            .textCase(.uppercase)
    }
}
