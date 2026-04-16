import Foundation
import AVFoundation
import Observation

// On-device audio recorder for tour creation.
// Records to AAC/m4a format — good compression, native iOS support.

@Observable
@MainActor
final class AudioRecorderService: NSObject {

    private(set) var isRecording: Bool = false
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var hasRecording: Bool = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private(set) var recordingURL: URL?
    private var maxDuration: TimeInterval = 300 // 5 minutes default

    // MARK: - Recording

    func startRecording(to url: URL, maxDuration: TimeInterval = 300) {
        self.recordingURL = url
        self.maxDuration = maxDuration

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64000,
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            recordingDuration = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isRecording else { return }
                    self.recordingDuration = self.recorder?.currentTime ?? 0
                    if self.recordingDuration >= self.maxDuration {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            print("AudioRecorderService: failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        recorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        hasRecording = true

        // Restore audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        } catch {
            print("AudioRecorderService: failed to restore audio session: \(error)")
        }
    }

    func deleteRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        hasRecording = false
        recordingDuration = 0
    }

    // MARK: - Playback preview

    private var previewPlayer: AVPlayer?

    func playPreview() {
        guard let url = recordingURL else { return }
        previewPlayer = AVPlayer(url: url)
        previewPlayer?.play()
    }

    func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
    }
}

extension AudioRecorderService: @preconcurrency AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
            self.hasRecording = flag
        }
    }
}
