import AVFoundation
import CoreLocation

@Observable
@MainActor
final class AudioAnnouncementService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var announcedPOIIds: Set<String> = []
    private(set) var isSpeaking = false

    static let maxAnnouncementDistance: Double = 2000 // meters

    override init() {
        super.init()
    }

    // MARK: - Tracking

    func hasAnnounced(_ poi: POI) -> Bool {
        announcedPOIIds.contains(poi.id)
    }

    func markAnnounced(_ poi: POI) {
        announcedPOIIds.insert(poi.id)
    }

    func shouldAnnounce(_ poi: POI, userLocation: CLLocation) -> Bool {
        guard !hasAnnounced(poi) else { return false }

        let poiLocation = CLLocation(latitude: poi.lat, longitude: poi.lng)
        let distance = userLocation.distance(from: poiLocation)
        return distance <= Self.maxAnnouncementDistance
    }

    // MARK: - Speech

    func announce(_ poi: POI, userLocation: CLLocation) {
        guard shouldAnnounce(poi, userLocation: userLocation) else { return }

        markAnnounced(poi)

        let utteranceText = "\(poi.name). \(poi.description)"
        let utterance = AVSpeechUtterance(string: utteranceText)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Configure audio session for voice prompt
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.interruptSpokenAudioAndMixWithOthers, .duckOthers]
            )
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        deactivateAudioSession()
        isSpeaking = false
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioAnnouncementService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.deactivateAudioSession()
        }
    }
}
