import SwiftUI
import CoreLocation
import UIKit
import CoreSwift

struct LocationStatusView: View {
    @Environment(LocationService.self) var locationService

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                    .font(.subheadline.weight(.medium))
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if locationService.authorizationStatus == .notDetermined {
                Button("Enable") {
                    locationService.requestAlwaysAuthorization()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else if locationService.authorizationStatus == .denied {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            } else if locationService.authorizationStatus == .authorizedWhenInUse {
                Button("Always On") {
                    locationService.requestAlwaysAuthorization()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .yellow
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }

    private var statusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "Always on — location updates active"
        case .authorizedWhenInUse:
            return "When in use — tap Always On for background updates"
        case .denied:
            return "Denied — enable in Settings > Privacy > Location"
        case .restricted:
            return "Restricted by device policy"
        case .notDetermined:
            return "Tap Enable to allow location access"
        @unknown default:
            return "Unknown status"
        }
    }
}
