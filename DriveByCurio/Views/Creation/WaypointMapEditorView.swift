import SwiftUI
import MapKit
import UIKit
import CoreSwift

// Tour creation — Step 2: drop waypoint pins on a map.
// User walks around, tapping "Add Stop" to drop a pin at their
// current GPS position. Each pin can be edited with title, trigger
// radius, and audio recordings.

struct WaypointMapEditorView: View {
    @State var tour: WalkingTour
    @Environment(WalkingTourStore.self) var tourStore
    @Environment(LocationService.self) var locationService
    @Environment(\.dismiss) var dismiss

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var editingWaypoint: WalkingWaypoint?
    @State private var showWaypointEditor = false
    @State private var showSaveConfirmation = false
    @State private var showLocationDeniedAlert = false
    @State private var showNoLocationToast = false

    private var locationAvailable: Bool {
        let status = locationService.authorizationStatus
        return (status == .authorizedWhenInUse || status == .authorizedAlways)
            && locationService.currentLocation != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(tour.waypoints) { wp in
                    Annotation(wp.title, coordinate: wp.coordinate) {
                        WaypointMarker(
                            number: wp.order,
                            hasAudio: wp.contentAudioFile != nil
                        )
                        .onTapGesture {
                            editingWaypoint = wp
                            showWaypointEditor = true
                        }
                    }
                }

                // Draw lines between waypoints
                if tour.waypoints.count >= 2 {
                    let coords = tour.waypoints.sorted { $0.order < $1.order }.map(\.coordinate)
                    MapPolyline(coordinates: coords)
                        .stroke(.blue.opacity(0.5), lineWidth: 3)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // Location permission overlay
            if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                locationDeniedOverlay
            } else if locationService.authorizationStatus == .notDetermined {
                locationPromptOverlay
            }

            // Bottom controls (only when location is authorized)
            if locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways {
                VStack(spacing: 12) {
                    // Toast when GPS not ready yet
                    if showNoLocationToast {
                        Text("Waiting for GPS fix...")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.orange.opacity(0.9), in: Capsule())
                            .foregroundStyle(.white)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Waypoint count
                    if !tour.waypoints.isEmpty {
                        Text("\(tour.waypoints.count) stop\(tour.waypoints.count == 1 ? "" : "s") added")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: Capsule())
                    }

                    HStack(spacing: 16) {
                        // Add Stop button
                        Button {
                            addWaypointAtCurrentLocation()
                        } label: {
                            Label("Add Stop Here", systemImage: "mappin.and.ellipse")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }

                        // Save button
                        if !tour.waypoints.isEmpty {
                            Button {
                                saveTour()
                            } label: {
                                Label("Save Tour", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showNoLocationToast)
        .navigationTitle(tour.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            requestLocationIfNeeded()
        }
        .sheet(isPresented: $showWaypointEditor) {
            if let wp = editingWaypoint, let index = tour.waypoints.firstIndex(where: { $0.id == wp.id }) {
                WaypointEditorView(
                    waypoint: $tour.waypoints[index],
                    tourId: tour.id,
                    onDelete: {
                        tour.waypoints.removeAll { $0.id == wp.id }
                        reorderWaypoints()
                        showWaypointEditor = false
                    }
                )
            }
        }
        .alert("Tour Saved!", isPresented: $showSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\"\(tour.title)\" with \(tour.waypoints.count) stops has been saved. You can find it in the tour browser.")
        }
        .alert("Location Access Required", isPresented: $showLocationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("DriveByCurio needs your location to drop pins where you're standing. Please enable Location Services in Settings.")
        }
    }

    // MARK: - Location overlays

    private var locationDeniedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red.opacity(0.7))

            Text("Location Access Denied")
                .font(.title3.weight(.bold))

            Text("DriveByCurio needs your location to place tour stops. Enable location access in Settings to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private var locationPromptOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Requesting Location Access...")
                .font(.headline)

            Text("Tap \"Allow While Using App\" when prompted.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func requestLocationIfNeeded() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestAlwaysAuthorization()
            locationService.startUpdating()
        case .authorizedWhenInUse, .authorizedAlways:
            locationService.startUpdating()
        case .denied, .restricted:
            showLocationDeniedAlert = true
        @unknown default:
            break
        }
    }

    private func addWaypointAtCurrentLocation() {
        guard let location = locationService.currentLocation else {
            // Show a brief toast instead of silently failing
            showNoLocationToast = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                showNoLocationToast = false
            }
            return
        }

        let waypointId = UUID().uuidString
        let order = tour.waypoints.count + 1

        let waypoint = WalkingWaypoint(
            id: waypointId,
            order: order,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            title: "Stop \(order)",
            description: "",
            triggerRadiusMeters: 30,
            contentAudioFile: nil,
            navAudioFile: nil,
            narrationText: nil,
            navInstructionText: nil
        )

        tour.waypoints.append(waypoint)

        // Open editor for the new waypoint
        editingWaypoint = waypoint
        showWaypointEditor = true
    }

    private func reorderWaypoints() {
        for i in tour.waypoints.indices {
            tour.waypoints[i].order = i + 1
        }
    }

    private func saveTour() {
        tour.updatedAt = Date()
        tourStore.saveUserTour(tour)
        showSaveConfirmation = true
    }
}

// MARK: - Waypoint Map Marker

struct WaypointMarker: View {
    let number: Int
    let hasAudio: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(hasAudio ? .green : .orange)
                .frame(width: 32, height: 32)
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .shadow(radius: 2)
    }
}
