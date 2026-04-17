import SwiftUI

// Audio recording screen — used for both content (5 min) and
// nav instructions (15 sec). Shows a big record button, timer,
// and max duration indicator.

struct RecordingView: View {
    let title: String
    let maxDuration: TimeInterval
    let targetURL: URL
    let onSaved: (URL) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var recorder = AudioRecorderService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Timer display
                Text(formatDuration(recorder.recordingDuration))
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(recorder.isRecording ? .red : .primary)

                // Max duration label
                Text("Max: \(formatDuration(maxDuration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Progress ring
                if recorder.isRecording {
                    ProgressView(
                        value: min(recorder.recordingDuration, maxDuration),
                        total: maxDuration
                    )
                    .progressViewStyle(.linear)
                    .tint(.red)
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Record / Stop button
                if recorder.isRecording {
                    Button {
                        recorder.stopRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.15))
                                .frame(width: 96, height: 96)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.red)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .accessibilityLabel("Stop recording")
                } else if recorder.hasRecording {
                    // Preview controls
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            Button {
                                recorder.playPreview()
                            } label: {
                                Label("Play", systemImage: "play.circle.fill")
                                    .font(.title2)
                            }

                            Button {
                                recorder.stopPreview()
                            } label: {
                                Label("Stop", systemImage: "stop.circle")
                                    .font(.title2)
                            }
                        }

                        HStack(spacing: 16) {
                            Button("Re-record") {
                                recorder.deleteRecording()
                                recorder.startRecording(to: targetURL, maxDuration: maxDuration)
                            }
                            .buttonStyle(.bordered)

                            Button("Save") {
                                onSaved(targetURL)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Button {
                        recorder.startRecording(to: targetURL, maxDuration: maxDuration)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.15))
                                .frame(width: 96, height: 96)
                            Circle()
                                .fill(.red)
                                .frame(width: 64, height: 64)
                        }
                    }
                    .accessibilityLabel("Start recording")

                    Text("Tap to record")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.stopRecording()
                        recorder.deleteRecording()
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let tenths = Int((seconds - Double(Int(seconds))) * 10)
        return String(format: "%d:%02d.%d", mins, secs, tenths)
    }
}
