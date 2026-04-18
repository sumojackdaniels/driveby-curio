import Foundation
import AVFoundation
import CoreLocation
import MediaPlayer
import Observation
import UIKit
import CoreSwift

// Tour playback engine.
//
// Responsibilities:
//   1. Hold the active Tour and the current waypoint index.
//   2. Stream the current waypoint's mp3 from the backend via AVPlayer.
//   3. Push title / subject / album / artwork to MPNowPlayingInfoCenter so
//      both the iOS lock screen and the CarPlay Now Playing template render
//      the right thing.
//   4. React to CLLocation updates: when the user enters the trigger circle
//      of the next waypoint AND we are not currently speaking the previous
//      one, advance and play the next narration.
//   5. Activate the AVAudioSession only on first play of a tour, never on
//      app launch — per CarPlay Audio guidance.
//
// Design notes:
// - Single AVPlayer instance, replaceCurrentItem on each waypoint advance.
// - The state machine treats waypoints as a strict ordered queue: we don't
//   skip around based on which is geographically closest, because for a
//   curated tour the *intended sequence* is what matters, not raw proximity.
// - "Have we already played this waypoint" is tracked per tour run, so
//   restarting a tour replays from the top.
// - manualAdvance() lets the user force-skip from the Now Playing "next"
//   button without waiting for a location trigger. This is also how iPhone
//   simulator users without a moving GPX can step through the tour by hand.

@Observable
@MainActor
final class TourPlayer: NSObject {

    // MARK: - Observable state

    private(set) var activeTour: Tour?
    private(set) var currentWaypointIndex: Int = 0
    private(set) var isPlaying: Bool = false
    private(set) var hasStarted: Bool = false
    private(set) var playedWaypointIDs: Set<String> = []

    var currentWaypoint: TourWaypoint? {
        guard let tour = activeTour else { return nil }
        guard currentWaypointIndex < tour.waypoints.count else { return nil }
        return tour.waypoints[currentWaypointIndex]
    }

    var upcomingWaypoints: [TourWaypoint] {
        guard let tour = activeTour else { return [] }
        let nextStart = currentWaypointIndex + 1
        guard nextStart < tour.waypoints.count else { return [] }
        return Array(tour.waypoints[nextStart...])
    }

    // MARK: - Dependencies

    private let tourService: TourService
    private let locationService: LocationService
    private let player: AVPlayer = AVPlayer()
    private var sessionActivated = false
    private var locationPollTimer: Timer?

    // MARK: - Init

    init(tourService: TourService, locationService: LocationService) {
        self.tourService = tourService
        self.locationService = locationService
        super.init()
        configureRemoteCommands()
    }

    // MARK: - Tour lifecycle

    /// Begin playback of a tour from waypoint index 0.
    /// Activates the audio session; this should be called only on an explicit
    /// user "Start tour" action.
    func startTour(_ tour: Tour) {
        activeTour = tour
        currentWaypointIndex = 0
        playedWaypointIDs = []
        hasStarted = true

        // Make sure CoreLocation is delivering fixes — both for the trigger
        // logic below and so the simulator's GPX-driven location pump has
        // an active manager to feed.
        locationService.startUpdating()
        startLocationPolling()

        activateAudioSessionIfNeeded()
        playCurrentWaypoint()
    }

    /// Stop playback and release the active tour.
    func endTour() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        activeTour = nil
        currentWaypointIndex = 0
        playedWaypointIDs = []
        isPlaying = false
        hasStarted = false
        stopLocationPolling()
        deactivateAudioSession()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Location polling
    //
    // The CarPlay scene also sets up its own observation loop, but we
    // duplicate it here so the iPhone-only path (no CarPlay window in the
    // simulator) still gets trigger-circle progression. Polling once per
    // second is cheap and ensures we don't miss the entry into a 200m
    // trigger circle even at a sim "fast forward" speed.

    private func startLocationPolling() {
        locationPollTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let location = self.locationService.currentLocation else { return }
                self.onLocationUpdate(location)
            }
        }
        locationPollTimer = timer
    }

    private func stopLocationPolling() {
        locationPollTimer?.invalidate()
        locationPollTimer = nil
    }

    /// Advance to the next waypoint, regardless of GPS position.
    /// Wired to the Now Playing "next" button and to the iPhone debug UI.
    func manualAdvance() {
        advanceWaypoint()
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingPlaybackState()
    }

    // MARK: - Location-driven progression

    /// Called from the CarPlay scene's location observer with each fix.
    /// If the user is inside the next waypoint's trigger circle, advance.
    func onLocationUpdate(_ location: CLLocation) {
        guard let tour = activeTour else { return }
        let nextIndex = currentWaypointIndex + 1
        guard nextIndex < tour.waypoints.count else { return }

        let nextWp = tour.waypoints[nextIndex]
        let distance = location.distance(from: nextWp.clLocation)

        // Debug: print current position and distance to next waypoint every ~10 seconds
        let tick = Int(Date().timeIntervalSince1970) % 10
        if tick == 0 {
            print("📍 Location: \(String(format: "%.5f", location.coordinate.latitude)), \(String(format: "%.5f", location.coordinate.longitude)) → next stop [\(nextIndex)] \"\(nextWp.title)\" is \(Int(distance))m away (trigger: \(Int(nextWp.trigger_radius_m))m)")
        }

        if distance <= nextWp.trigger_radius_m {
            print("🎯 TRIGGERED: entering \"\(nextWp.title)\" at \(Int(distance))m")
            advanceWaypoint()
        }
    }

    // MARK: - Internal advancement

    private func advanceWaypoint() {
        guard let tour = activeTour else { return }
        let nextIndex = currentWaypointIndex + 1
        guard nextIndex < tour.waypoints.count else {
            // At the end of the tour — stop after the last story finishes.
            return
        }
        currentWaypointIndex = nextIndex
        playCurrentWaypoint()
    }

    private func playCurrentWaypoint() {
        guard let tour = activeTour, let waypoint = currentWaypoint else { return }
        playedWaypointIDs.insert(waypoint.id)

        let url = tourService.audioURL(tourId: tour.id, waypointId: waypoint.id)
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true

        updateNowPlayingInfo(tour: tour, waypoint: waypoint)
    }

    // MARK: - Audio session

    private func activateAudioSessionIfNeeded() {
        guard !sessionActivated else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback + duckOthers: we are primary audio, but Apple Maps
            // turn-by-turn voice prompts should duck (not pause) us.
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            sessionActivated = true
        } catch {
            print("TourPlayer: failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        guard sessionActivated else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionActivated = false
        } catch {
            print("TourPlayer: failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Now Playing info

    private func updateNowPlayingInfo(tour: Tour, waypoint: TourWaypoint) {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = waypoint.title
        info[MPMediaItemPropertyArtist] = waypoint.subject
        info[MPMediaItemPropertyAlbumTitle] = tour.title
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

        // Tour cover art placeholder — see CARPLAY-CONSTRAINTS.md, the artwork
        // slot must be a "tour cover" not a per-story image.
        // For milestone 1 we render a solid-color placeholder; real tour cover
        // art is a follow-up.
        if let placeholder = TourPlayer.makePlaceholderArtwork(title: tour.title) {
            // Capture the pre-rendered image by value. The @Sendable annotation
            // breaks MainActor isolation inheritance so MediaPlayer can call this
            // on its internal accessQueue without tripping the actor-isolation check.
            let artworkImage = placeholder
            let artworkSize = placeholder.size
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkSize) { @Sendable _ in artworkImage }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private static func makePlaceholderArtwork(title: String) -> UIImage? {
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(red: 0.10, green: 0.18, blue: 0.32, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let para = NSMutableParagraphStyle()
            para.alignment = .center
            para.lineBreakMode = .byWordWrapping

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 56, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: para,
            ]
            let inset: CGFloat = 40
            let textRect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
            (title as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }

    // MARK: - Remote command center (Now Playing buttons + steering wheel)

    private func configureRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isPlaying else { return }
                self.togglePlayPause()
            }
            return .success
        }

        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.togglePlayPause()
            }
            return .success
        }

        cc.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.manualAdvance()
            }
            return .success
        }
    }
}

