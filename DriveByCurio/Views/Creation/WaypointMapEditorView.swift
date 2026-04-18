import SwiftUI
import MapKit
import UIKit
import CoreSwift

// Tour creation — Step 2: drop stop pins on a map.
// User walks around, tapping "Add Stop" to drop a pin at their
// current GPS position. Each pin can be edited with title, trigger
// radius, and audio recordings.

struct StopMapEditorView: View {
    @State var tour: WalkingTour
    var onSaved: (() -> Void)?
    @Environment(WalkingTourStore.self) var tourStore
    @Environment(LocationService.self) var locationService
    @Environment(\.dismiss) var dismiss

    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.98, longitude: -77.10),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    )
    @State private var hasCenteredOnUser = false
    @State private var editingStopID: String?
    @State private var showSaveConfirmation = false
    @State private var showLocationDeniedAlert = false
    @State private var showNoLocationToast = false
    @State private var showDebugNoLocationAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(tour.stops) { stop in
                    Annotation(stop.title, coordinate: stop.coordinate) {
                        StopMarker(
                            number: stop.order,
                            hasAudio: stop.segments.contains { $0.audioFile != nil }
                        )
                        .onTapGesture {
                            editingStopID = stop.id
                        }
                    }
                }

                // Draw lines between stops
                if tour.stops.count >= 2 {
                    let coords = tour.stops.sorted { $0.order < $1.order }.map(\.coordinate)
                    MapPolyline(coordinates: coords)
                        .stroke(.blue.opacity(0.5), lineWidth: 3)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // Bottom controls
            VStack(spacing: 12) {
                // Brief toast when user taps Add Stop but GPS isn't ready
                if showNoLocationToast {
                    Text("Waiting for GPS fix...")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.9), in: Capsule())
                        .foregroundStyle(.white)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Stop count
                if !tour.stops.isEmpty {
                    Text("\(tour.stops.count) stop\(tour.stops.count == 1 ? "" : "s") added")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
                }

                HStack(spacing: 16) {
                    // Add Stop button
                    Button {
                        addStopAtCurrentLocation()
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
                    if !tour.stops.isEmpty {
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
        .animation(.easeInOut(duration: 0.3), value: showNoLocationToast)
        .navigationTitle(tour.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            requestLocationIfNeeded()
        }
        .sheet(isPresented: Binding(
            get: { editingStopID != nil },
            set: { if !$0 { editingStopID = nil } }
        )) {
            if let id = editingStopID,
               let index = tour.stops.firstIndex(where: { $0.id == id }) {
                StopEditorView(
                    stop: $tour.stops[index],
                    tourId: tour.id,
                    onDelete: {
                        tour.stops.removeAll { $0.id == id }
                        reorderStops()
                        editingStopID = nil
                    }
                )
            }
        }
        .alert("Tour Saved!", isPresented: $showSaveConfirmation) {
            Button("OK") {
                if let onSaved {
                    onSaved()
                } else {
                    dismiss()
                }
            }
        } message: {
            Text("\"\(tour.title)\" with \(tour.stops.count) stops has been saved. You can find it in the tour browser.")
        }
        #if DEBUG
        .alert("No Location Data", isPresented: $showDebugNoLocationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Location permission is granted but no GPS fix is available. On the simulator, use Debug → Simulate Location or load a GPX file to provide a location.")
        }
        #endif
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

    private func requestLocationIfNeeded() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestWhenInUseAuthorization()
            locationService.startUpdating()
        case .authorizedWhenInUse, .authorizedAlways:
            locationService.startUpdating()
        case .denied, .restricted:
            showLocationDeniedAlert = true
        @unknown default:
            break
        }
    }

    private func addStopAtCurrentLocation() {
        guard let location = locationService.currentLocation else {
            #if DEBUG
            if locationService.authorizationStatus == .authorizedWhenInUse
                || locationService.authorizationStatus == .authorizedAlways {
                showDebugNoLocationAlert = true
            } else {
                showNoLocationToast = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showNoLocationToast = false
                }
            }
            #else
            showNoLocationToast = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                showNoLocationToast = false
            }
            #endif
            return
        }

        let stopId = UUID().uuidString
        let order = tour.stops.count + 1

        // Create a stop with a single empty narration segment
        let segment = TourSegment(
            id: "\(stopId)-narration",
            kind: .narration,
            title: "Stop \(order)",
            description: "",
            durationSeconds: 60,
            audioFile: nil,
            narrationText: nil
        )

        let stop = TourStop(
            id: stopId,
            order: order,
            title: "Stop \(order)",
            description: "",
            address: "",
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            triggerRadiusMeters: 30,
            segments: [segment],
            navAudioFile: nil,
            navInstructionText: nil
        )

        tour.stops.append(stop)

        // Open editor for the new stop
        editingStopID = stop.id
    }

    private func reorderStops() {
        for i in tour.stops.indices {
            tour.stops[i].order = i + 1
        }
    }

    private func saveTour() {
        tour.paths = WalkingTour.computePaths(from: tour.stops)
        tour.updatedAt = Date()
        tourStore.saveUserTour(tour)
        showSaveConfirmation = true
    }
}

// MARK: - Stop Map Marker

struct StopMarker: View {
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
