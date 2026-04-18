import SwiftUI

// MARK: - Stop Timeline Row
//
// A single stop in the tour overview timeline. Shows:
// - Vertical connecting line to next stop
// - Status dot (pending/done/arrived/playing/approaching)
// - Stop label with contextual state
// - Title and blurb
// - Expandable segment list

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
            // Timeline column (dot only — line drawn via .background)
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

                // Segment count badge (when more than one segment)
                if segments.count > 1 && !isExpanded {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: 9))
                        Text("\(segments.count) segments")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(TourTokens.moss)
                    .padding(.top, 4)
                }

                // Expanded: segment list
                if isExpanded {
                    expandedSegments
                        .padding(.top, 10)
                }
            }
        }
        .padding(.bottom, 20)
        // IMPORTANT: Connecting line is drawn as a .background so that
        // GeometryReader inherits an already-resolved size. Placing
        // GeometryReader as a direct child of ScrollView > VStack > ForEach
        // causes a layout negotiation deadlock and blank screens on
        // NavigationStack push.
        .background(alignment: .topLeading) {
            if !isLast {
                GeometryReader { geo in
                    if isTransitFromHere {
                        Path { path in
                            path.move(to: CGPoint(x: 11.5, y: 28))
                            path.addLine(to: CGPoint(x: 11.5, y: geo.size.height))
                        }
                        .stroke(TourTokens.ember, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    } else {
                        Rectangle()
                            .fill(stopState == .done || stopState == .playing || stopState == .arrived ? TourTokens.moss : TourTokens.faint)
                            .frame(width: 1.5)
                            .offset(x: 10.75, y: 28)
                    }
                }
                .frame(width: 34)
            }
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        ZStack {
            switch stopState {
            case .arrived, .playing:
                Circle()
                    .fill(TourTokens.moss.opacity(0.25))
                    .frame(width: 24, height: 24)
                    .modifier(PulseAnimation())
                Circle()
                    .fill(TourTokens.moss)
                    .frame(width: 16, height: 16)

            case .approaching:
                Circle()
                    .fill(TourTokens.ember.opacity(0.25))
                    .frame(width: 24, height: 24)
                    .modifier(PulseAnimation())
                Circle()
                    .fill(TourTokens.ember)
                    .frame(width: 16, height: 16)

            case .done:
                Circle()
                    .fill(TourTokens.moss)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    )

            case .current:
                Circle()
                    .fill(TourTokens.ink)
                    .frame(width: 16, height: 16)

            case .pending:
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
