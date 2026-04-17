import SwiftUI

// MARK: - Stop Timeline Row
//
// A single stop in the tour overview timeline. Shows:
// - Vertical connecting line to next stop
// - Status dot (pending/done/arrived/playing/approaching)
// - Stop label with contextual state
// - Title and blurb
// - Expandable segment list
//
// Standard SwiftUI throughout. The timeline dot + connecting line uses
// ZStack overlays rather than custom drawing.

struct StopTimelineRow: View {
    let stop: TourStop
    let index: Int
    let totalStops: Int
    let segments: [TourSegment]

    // State
    var stopState: StopState = .pending
    var isExpanded: Bool = false
    var activeSegmentIndex: Int = 0
    var isPlaying: Bool = false

    // Path to next stop (for dashed transit line)
    var pathToNext: TourPath?
    var isTransitFromHere: Bool = false

    enum StopState {
        case pending
        case done
        case current
        case arrived      // at stop, not playing
        case playing      // at stop, audio playing
        case approaching  // in transit, this is the target
    }

    private var isLast: Bool { index == totalStops - 1 }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline column (dot only — the connecting line is drawn
            // as a background on the full row so it inherits the row's
            // height without needing a greedy GeometryReader)
            ZStack(alignment: .top) {
                statusDot
                    .offset(y: 6)
            }
            .frame(width: 34)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Status label
                statusLabel

                // Title
                Text(stop.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(TourTokens.ink)
                    .lineSpacing(2)

                // Blurb
                Text(stop.description)
                    .font(.footnote)
                    .foregroundStyle(TourTokens.ink2)
                    .lineSpacing(2)
                    .padding(.top, 2)

                // Expanded: segment list
                if isExpanded {
                    expandedSegments
                        .padding(.top, 10)
                }
            }
        }
        .padding(.bottom, 20)
        // Connecting line drawn as a background on the full row.
        // This inherits the row's resolved height, avoiding the
        // unconstrained GeometryReader that caused layout deadlock.
        .background(alignment: .topLeading) {
            if !isLast {
                connectingLine
                    .padding(.top, 22)
            }
        }
    }

    // MARK: - Connecting Line
    //
    // Drawn as a .background on the row body so it inherits the full
    // resolved row height. This replaces the previous bare GeometryReader
    // which caused a layout deadlock inside ScrollView > VStack on
    // NavigationStack push (blank screen until background/foreground).

    @ViewBuilder
    private var connectingLine: some View {
        if isTransitFromHere {
            // Dashed line for in-transit.
            // The GeometryReader here is safe because it lives inside
            // an .overlay on a Rectangle that already has its size
            // resolved from the row background.
            Rectangle()
                .fill(.clear)
                .frame(width: 24)
                .overlay {
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 11.5, y: 0))
                            path.addLine(to: CGPoint(x: 11.5, y: geo.size.height))
                        }
                        .stroke(TourTokens.ember, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }
                }
        } else {
            // Solid line — no GeometryReader needed, just fill the
            // available height from the background modifier.
            Rectangle()
                .fill(stopState == .done || stopState == .playing || stopState == .arrived ? TourTokens.moss : TourTokens.faint)
                .frame(width: 1.5)
                .offset(x: 10.75)
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        ZStack {
            switch stopState {
            case .arrived, .playing:
                // Green pulse
                Circle()
                    .fill(TourTokens.moss.opacity(0.25))
                    .frame(width: 24, height: 24)
                    .modifier(PulseAnimation())
                Circle()
                    .fill(TourTokens.moss)
                    .frame(width: 16, height: 16)

            case .approaching:
                // Orange pulse
                Circle()
                    .fill(TourTokens.ember.opacity(0.25))
                    .frame(width: 24, height: 24)
                    .modifier(PulseAnimation())
                Circle()
                    .fill(TourTokens.ember)
                    .frame(width: 16, height: 16)

            case .done:
                // Moss with checkmark
                Circle()
                    .fill(TourTokens.moss)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    )

            case .current:
                // Ink filled
                Circle()
                    .fill(TourTokens.ink)
                    .frame(width: 16, height: 16)

            case .pending:
                // Empty with border
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(TourTokens.faint, lineWidth: 2)
                    )
            }
        }
        .frame(width: 24, height: 24)
    }

    // MARK: - Status Label

    @ViewBuilder
    private var statusLabel: some View {
        switch stopState {
        case .arrived, .playing:
            Text("YOU ARE HERE")
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(0.6)
                .foregroundStyle(TourTokens.moss)

        case .approaching:
            Text("HEAD HERE NOW")
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(0.6)
                .foregroundStyle(TourTokens.ember)

        default:
            Text("STOP \(stop.order)")
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(0.6)
                .foregroundStyle(TourTokens.muted)
        }
    }

    // MARK: - Expanded Segments

    private var expandedSegments: some View {
        VStack(spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { i, segment in
                SegmentListRow(
                    segment: segment,
                    isActive: i == activeSegmentIndex,
                    isPlaying: i == activeSegmentIndex && isPlaying
                )
            }
        }
    }
}

// MARK: - Pulse Animation

/// Looping scale+fade pulse for status dots.
/// NOTE: Custom modifier — no built-in SwiftUI pulse animation matches the
/// concentric-ring design from the wireframe.
private struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 2.1 : 1.0)
            .opacity(isPulsing ? 0.0 : 0.5)
            .animation(
                .easeOut(duration: 1.6)
                .repeatForever(autoreverses: false),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
