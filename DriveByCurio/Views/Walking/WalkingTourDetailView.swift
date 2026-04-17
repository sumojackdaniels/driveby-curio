import SwiftUI
import MapKit

// Tour detail — now routes to the new Tour Consumption overview.

struct WalkingTourDetailView: View {
    let tour: WalkingTour

    var body: some View {
        TourOverviewView(tour: tour)
    }
}

// MARK: - Waypoint Preview Map
//
// Reusable map showing numbered pins and a connecting polyline.
// Used by TourOverviewView and the creation flow.

struct WaypointPreviewMap: View {
    let waypoints: [TourStop]

    var body: some View {
        Map {
            ForEach(waypoints) { wp in
                Annotation(wp.title, coordinate: wp.coordinate) {
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 24, height: 24)
                        Text("\(wp.order)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }

            if waypoints.count >= 2 {
                let coords = waypoints.sorted { $0.order < $1.order }.map(\.coordinate)
                MapPolyline(coordinates: coords)
                    .stroke(.green.opacity(0.6), lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }
}
