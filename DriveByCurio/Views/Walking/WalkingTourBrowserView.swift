import SwiftUI
import CoreSwift

// Walking tour browser — redesigned to match the Tour Consumption wireframe.
//
// Layout:
// - "Tours" large title + profile avatar
// - Hero unit: highlighted nearby tour (community-forward mosaic)
// - "More stories" section: feed cards with photo + map placeholder
// - Docked playing banner at bottom (when a tour is active)

struct WalkingTourBrowserView: View {
    @Environment(WalkingTourStore.self) var tourStore
    @Environment(WalkingTourPlayer.self) var player
    @State private var showCreateTour = false

    private var allTours: [WalkingTour] {
        tourStore.authoredTours + tourStore.userTours
    }

    private var heroTour: WalkingTour? {
        allTours.first
    }

    private var feedTours: [WalkingTour] {
        Array(allTours.dropFirst())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Top nav: "Tours" + avatar
                        topNav

                        // Hero unit
                        if let hero = heroTour {
                            NavigationLink {
                                WalkingTourDetailView(tour: hero)
                            } label: {
                                TourHeroCard(tour: hero)
                            }
                            .buttonStyle(.plain)
                        }

                        // Feed section
                        if !feedTours.isEmpty {
                            feedSection
                        }

                        // Bottom padding for banner
                        Spacer().frame(height: player.activeTour != nil ? 120 : 40)
                    }
                }
                .background(Color(.systemGroupedBackground))

                // Docked playing banner
                if let activeTour = player.activeTour {
                    NavigationLink {
                        WalkingTourDetailView(tour: activeTour)
                    } label: {
                        DockedPlayerBanner(
                            tour: activeTour,
                            currentStopIndex: min(player.currentWaypointIndex, activeTour.sortedStops.count - 1),
                            atStop: !player.hasStarted || (player.playbackMode == .listening && !player.isPlaying)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateTour = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateTour) {
                CreateTourView()
            }
        }
    }

    // MARK: - Top Nav

    private var topNav: some View {
        HStack(alignment: .bottom) {
            Text("Tours")
                .font(.system(size: 34, weight: .bold))

            Spacer()

            // Profile avatar
            Circle()
                .fill(TourTokens.mossSoft)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("YO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(TourTokens.moss)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.08), radius: 1.5, y: 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 62)
        .padding(.bottom, 8)
    }

    // MARK: - Feed Section

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            VStack(alignment: .leading, spacing: 2) {
                Text("More stories nearby")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("\(feedTours.count) tours from \(uniqueCreatorCount) guides")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Feed units
            VStack(spacing: 28) {
                ForEach(feedTours) { tour in
                    NavigationLink {
                        WalkingTourDetailView(tour: tour)
                    } label: {
                        TourFeedCard(tour: tour)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    private var uniqueCreatorCount: Int {
        Set(feedTours.map(\.creatorName)).count
    }
}

// MARK: - Hero Card
//
// Community-forward hero unit matching the wireframe's "Highlighted nearby" treatment.
// Full-bleed photo with gradient, author chip, quote, walk/bike times, Play pill.

private struct TourHeroCard: View {
    let tour: WalkingTour

    var body: some View {
        ZStack(alignment: .bottom) {
            // Photo
            PhotoPlaceholder(label: "guide portrait", height: 340, cornerRadius: 0)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Gradient
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.38),
                    .init(color: .black.opacity(0.78), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Badge
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        // Pulsing dot
                        ZStack {
                            Circle().fill(.white).frame(width: 4, height: 4)
                            Circle().fill(.white.opacity(0.5)).frame(width: 8, height: 8)
                        }
                        Text("HIGHLIGHTED NEARBY")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .tracking(0.5)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2))
                    .background(.ultraThinMaterial.opacity(0.4))
                    .clipShape(Capsule())

                    Spacer()
                }
                .padding(.top, 14)
                .padding(.leading, 14)

                Spacer()
            }

            // Bottom content
            VStack(alignment: .leading, spacing: 0) {
                // Author
                HStack(spacing: 8) {
                    Circle()
                        .fill(TourTokens.mossSoft)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(tour.author.initials)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(TourTokens.moss)
                        )
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(tour.author.name)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text(tour.author.role)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                // Quote
                Text("\"\(tour.coverQuote)\"")
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .padding(.top, 12)

                // Title + meta + Play
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tour.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        // Walk · Bike estimates
                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 10))
                                Text("\(tour.totalWalkMinutes)m")
                            }
                            Divider()
                                .frame(height: 10)
                                .background(.white.opacity(0.3))
                            HStack(spacing: 4) {
                                Image(systemName: "bicycle")
                                    .font(.system(size: 10))
                                Text("\(tour.totalBikeMinutes)m")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    // Play pill
                    Text("Play")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Feed Card
//
// Split card: 2/3 photo with topic tags + 1/3 map placeholder with walk/bike estimates.
// Title, author + rating sit below the card — Airbnb-style.

private struct TourFeedCard: View {
    let tour: WalkingTour
    private let cardHeight: CGFloat = 148

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card: photo + map
            HStack(spacing: 0) {
                // Photo (2/3)
                photoSection

                // Map placeholder (1/3)
                mapSection
            }
            .frame(height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)

            // Text below card
            textSection
        }
    }

    // Photo with topic tags overlay
    private var photoSection: some View {
        ZStack(alignment: .bottom) {
            PhotoPlaceholder(
                label: "\(tour.title) photo",
                height: cardHeight,
                cornerRadius: 0
            )

            // Bottom gradient for tag legibility
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.55),
                    .init(color: .black.opacity(0.7), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Topic tags
            HStack(spacing: 6) {
                ForEach(tour.tags.prefix(3), id: \.self) { tag in
                    Text(tag.capitalized)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .tracking(0.1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.22))
                        .background(.ultraThinMaterial.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .layoutPriority(2) // Takes 2/3 of space
    }

    // Map placeholder with walk/bike estimates
    private var mapSection: some View {
        VStack(spacing: 0) {
            // Map placeholder
            ZStack {
                Color(.systemGray6)
                // Diagonal hatch
                Canvas { context, size in
                    for i in stride(from: 0, to: size.width + size.height, by: 10) {
                        var path = Path()
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i - size.height, y: size.height))
                        context.stroke(path, with: .color(.gray.opacity(0.12)), lineWidth: 0.6)
                    }
                }
                Text("[map]")
                    .font(.system(size: 10, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary.opacity(0.6))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Walk/bike estimates
            Divider()
            HStack(spacing: 0) {
                // Walk
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 9))
                    Text("\(tour.totalWalkMinutes)m")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(TourTokens.ink2)

                Divider().frame(height: 14)

                // Bike
                HStack(spacing: 4) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 9))
                    Text("\(tour.totalBikeMinutes)m")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(TourTokens.ink2)
            }
            .padding(.vertical, 6)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(TourTokens.hairline)
                .frame(width: 0.5),
            alignment: .leading
        )
        .frame(maxWidth: .infinity)
        .layoutPriority(1) // Takes 1/3 of space
    }

    // Title + author + rating below the card
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title + rating
            HStack(alignment: .firstTextBaseline) {
                Text(tour.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                // Rating (placeholder)
                HStack(spacing: 3) {
                    Text("4.\(tour.waypoints.count)")
                        .fontWeight(.medium)
                    Text("⭐️")
                        .font(.caption)
                }
                .font(.subheadline)
            }

            // Author
            HStack(spacing: 4) {
                Text("with")
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(TourTokens.mossSoft)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(tour.author.initials)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(TourTokens.moss)
                    )

                Text(tour.author.name)
                    .foregroundStyle(TourTokens.ink2)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(tour.author.role)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.footnote)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}
