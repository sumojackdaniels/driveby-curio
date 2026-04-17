import SwiftUI

// Per-waypoint editor — set title, trigger radius, record content
// audio (up to 5 min) and nav instruction audio (up to 15 sec).

struct WaypointEditorView: View {
    @Binding var waypoint: TourStop
    let tourId: String
    let onDelete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showContentRecorder = false
    @State private var showNavRecorder = false

    private let storage = TourStorageService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Stop Info") {
                    TextField("Title", text: $waypoint.title)
                    TextField("Description (optional)", text: $waypoint.description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Trigger Area") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How close should someone be to trigger this stop?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(Int(waypoint.triggerRadiusMeters))m")
                                .font(.headline)
                                .monospacedDigit()
                                .frame(width: 50)

                            Slider(
                                value: $waypoint.triggerRadiusMeters,
                                in: 10...100,
                                step: 5
                            )
                        }

                        Text(radiusDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Story Recording (up to 5 min)") {
                    if hasContentAudio {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Recording saved")
                            Spacer()
                            Button("Re-record") {
                                showContentRecorder = true
                            }
                            .font(.subheadline)
                        }
                    } else {
                        Button {
                            showContentRecorder = true
                        } label: {
                            Label("Record Story", systemImage: "mic.fill")
                        }
                    }
                }

                Section("Direction to Next Stop (up to 15 sec)") {
                    if waypoint.navAudioFile != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Direction saved")
                            Spacer()
                            Button("Re-record") {
                                showNavRecorder = true
                            }
                            .font(.subheadline)
                        }
                    } else {
                        Button {
                            showNavRecorder = true
                        } label: {
                            Label("Record Direction", systemImage: "location.fill")
                        }
                    }
                }

                Section("Location") {
                    HStack {
                        Text("Lat")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.5f", waypoint.lat))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Lng")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.5f", waypoint.lng))
                            .monospacedDigit()
                    }
                }

                Section {
                    Button("Delete Stop", role: .destructive) {
                        onDelete()
                    }
                }
            }
            .navigationTitle("Stop \(waypoint.order)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showContentRecorder) {
                RecordingView(
                    title: "Record Story",
                    maxDuration: 300,
                    targetURL: storage.contentAudioURL(tourId: tourId, stopId: waypoint.id)
                ) { url in
                    // Create or update the narration segment
                    if let idx = waypoint.segments.firstIndex(where: { $0.kind == .narration }) {
                        waypoint.segments[idx].audioFile = "content.m4a"
                    } else {
                        waypoint.segments.append(TourSegment(
                            id: "\(waypoint.id)-narration",
                            kind: .narration,
                            title: waypoint.title,
                            description: "",
                            durationSeconds: 180,
                            audioFile: "content.m4a"
                        ))
                    }
                }
            }
            .sheet(isPresented: $showNavRecorder) {
                RecordingView(
                    title: "Record Direction",
                    maxDuration: 15,
                    targetURL: storage.navAudioURL(tourId: tourId, stopId: waypoint.id)
                ) { url in
                    waypoint.navAudioFile = "nav.m4a"
                }
            }
        }
    }

    private var hasContentAudio: Bool {
        waypoint.segments.contains { $0.audioFile != nil }
    }

    private var radiusDescription: String {
        let r = Int(waypoint.triggerRadiusMeters)
        if r <= 20 { return "Very close — about a house width away" }
        if r <= 40 { return "Close — about half a block" }
        if r <= 70 { return "Medium — a comfortable approach distance" }
        return "Wide — starts well before arrival"
    }
}
