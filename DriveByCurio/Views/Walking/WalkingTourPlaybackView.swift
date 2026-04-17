import SwiftUI
import MapKit
import CoreLocation
import CoreSwift

// Walking tour playback — renders the three modes:
//   1. Listening: audio controls + current stop info
//   2. Nav Instruction: "Getting to the next stop..." + audio
//   3. Compass: heading arrow + distance + mini map + navigate button

struct WalkingTourPlaybackView: View {
    let tour: WalkingTour
    @Environment(WalkingTourPlayer.self) var player
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            tourHeader

            // Mode-specific content
            ScrollView {
                switch player.playbackMode {
                case .listening:
                    listeningMode
                case .navInstruction:
                    navInstructionMode
                case .compass:
                    compassMode
                case .finished:
                    finishedMode
                }
            }

            // Bottom controls
            bottomControls
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("End Tour") {
                    player.endTour()
                    dismiss()
                }
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Tour Header

    private var tourHeader: some View {
        VStack(spacing: 4) {
            Text(tour.title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
            if let wp = player.currentWaypoint {
                Text(wp.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            Text("Stop \(player.currentWaypointIndex + 1) of \(tour.stops.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(modeGradient)
    }

    private var modeGradient: LinearGradient {
        switch player.playbackMode {
        case .listening:
            LinearGradient(colors: [.green.opacity(0.8), .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .navInstruction:
            LinearGradient(colors: [.orange, .yellow.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .compass:
            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .finished:
            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: - Listening Mode

    private var listeningMode: some View {
        VStack(spacing: 20) {
            if let wp = player.currentWaypoint {
                // Waypoint info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "headphones")
                            .foregroundStyle(.green)
                        Text("Now Playing")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }

                    Text(wp.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // Progress bar
                    if player.audioDuration > 0 {
                        VStack(spacing: 4) {
                            ProgressView(value: player.audioCurrentTime, total: player.audioDuration)
                                .tint(.green)
                            HStack {
                                Text(formatTime(player.audioCurrentTime))
                                Spacer()
                                Text(formatTime(player.audioDuration))
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
    }

    // MARK: - Nav Instruction Mode

    private var navInstructionMode: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)

                Text("Getting to the next stop...")
                    .font(.headline)

                if let next = player.nextWaypoint {
                    Text(next.title)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)
                }

                if player.audioDuration > 0 {
                    ProgressView(value: player.audioCurrentTime, total: player.audioDuration)
                        .tint(.orange)
                        .padding(.horizontal)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding()
    }

    // MARK: - Compass Mode

    private var compassMode: some View {
        VStack(spacing: 20) {
            if let next = player.nextWaypoint {
                // Compass arrow
                VStack(spacing: 8) {
                    CompassArrowView(
                        bearing: player.bearingToNextStop,
                        heading: player.currentTrueHeading
                    )
                    .frame(width: 120, height: 120)

                    Text(formatDistance(player.distanceToNextStop))
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("to \(next.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Mini map
                if let route = player.walkingRoute {
                    WalkingRouteMapView(route: route, destination: next)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Navigate button
                Button {
                    player.openMapsToNextStop()
                } label: {
                    Label("Navigate in Maps", systemImage: "map.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }

    // MARK: - Finished Mode

    private var finishedMode: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Tour Complete!")
                .font(.title2.weight(.bold))

            Text("You've completed \"\(tour.title)\"")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                player.endTour()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .padding(.top, 40)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 24) {
            // Play/Pause (only in listening or nav modes)
            if player.playbackMode == .listening || player.playbackMode == .navInstruction {
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.primary)
                }
            }

            // Next stop
            if !player.isLastStop {
                Button {
                    player.manualAdvance()
                } label: {
                    Label("Next Stop", systemImage: "forward.fill")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: Capsule())
                }
            }
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}

// MARK: - Compass Arrow

struct CompassArrowView: View {
    let bearing: Double
    let heading: Double

    private var rotation: Double {
        bearing - heading
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.3), lineWidth: 2)

            Image(systemName: "location.north.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .rotationEffect(.degrees(rotation))
                .animation(.easeInOut(duration: 0.3), value: rotation)
        }
    }
}

// MARK: - Walking Route Map

struct WalkingRouteMapView: UIViewRepresentable {
    let route: MKRoute
    let destination: TourStop

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        mapView.addOverlay(route.polyline)

        let annotation = MKPointAnnotation()
        annotation.coordinate = destination.coordinate
        annotation.title = destination.title
        mapView.addAnnotation(annotation)

        let rect = route.polyline.boundingMapRect
        let insets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        mapView.setVisibleMapRect(rect, edgePadding: insets, animated: false)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
