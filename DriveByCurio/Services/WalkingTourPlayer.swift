import Foundation
import AVFoundation
import CoreLocation
import MapKit
import MediaPlayer
import Observation
import UIKit
import CoreSwift

// Walking tour playback engine with three modes:
//
//   1. LISTENING — content audio is playing. Show playback controls.
//   2. NAV_INSTRUCTION — short direction audio between stops.
//   3. COMPASS — wayfinding to next stop (heading arrow + distance).
//
// State machine:
//   Start tour → play stop 1 content → LISTENING
//   Content finishes → play nav instruction → NAV_INSTRUCTION
//   Nav finishes (or none) → COMPASS
//   Enter next trigger circle → play next content → LISTENING
//   ... repeat until last stop
//   Last stop content finishes → tour complete

enum WalkingPlaybackMode: Equatable {
    case listening
    case navInstruction
    case compass
    case finished
}

@Observable
@MainActor
final class WalkingTourPlayer: NSObject {

    // MARK: - Observable state

    private(set) var activeTour: WalkingTour?
    private(set) var currentWaypointIndex: Int = 0
    private(set) var isPlaying: Bool = false
    private(set) var hasStarted: Bool = false
    private(set) var playbackMode: WalkingPlaybackMode = .listening

    // Compass / wayfinding
    private(set) var currentHeading: CLHeading?
    private(set) var bearingToNextStop: Double = 0
    private(set) var distanceToNextStop: Double = 0
    private(set) var walkingRoute: MKRoute?

    // Audio progress
    private(set) var audioDuration: TimeInterval = 0
    private(set) var audioCurrentTime: TimeInterval = 0

    var currentWaypoint: WalkingWaypoint? {
        guard let tour = activeTour else { return nil }
        guard currentWaypointIndex < tour.waypoints.count else { return nil }
        return tour.waypoints[currentWaypointIndex]
    }

    var nextWaypoint: WalkingWaypoint? {
        guard let tour = activeTour else { return nil }
        let next = currentWaypointIndex + 1
        guard next < tour.waypoints.count else { return nil }
        return tour.waypoints[next]
    }

    var isLastStop: Bool {
        guard let tour = activeTour else { return true }
        return currentWaypointIndex >= tour.waypoints.count - 1
    }

    // MARK: - Dependencies

    private let locationService: LocationService
    private let storage = TourStorageService.shared
    private let player = AVPlayer()
    private let locationManager = CLLocationManager()
    private var sessionActivated = false
    private var locationPollTimer: Timer?
    private var progressTimer: Timer?
    private var playerEndObserver: NSObjectProtocol?

    // MARK: - Init

    init(locationService: LocationService) {
        self.locationService = locationService
        super.init()
        locationManager.delegate = self
        configureRemoteCommands()
    }

    // MARK: - Tour lifecycle

    func startTour(_ tour: WalkingTour) {
        activeTour = tour
        currentWaypointIndex = 0
        hasStarted = true
        playbackMode = .listening

        locationService.startUpdating()
        locationManager.startUpdatingHeading()
        startLocationPolling()
        activateAudioSessionIfNeeded()
        playContentAudio()
    }

    func endTour() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        removePlayerEndObserver()
        activeTour = nil
        currentWaypointIndex = 0
        isPlaying = false
        hasStarted = false
        playbackMode = .listening
        walkingRoute = nil
        stopLocationPolling()
        stopProgressTimer()
        locationManager.stopUpdatingHeading()
        deactivateAudioSession()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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

    func manualAdvance() {
        advanceToNextStop()
    }

    // MARK: - Playback state machine

    private func playContentAudio() {
        guard let tour = activeTour, let waypoint = currentWaypoint else { return }

        if let url = storage.resolveContentAudioURL(tour: tour, waypoint: waypoint) {
            playbackMode = .listening
            playAudio(url: url)
            updateNowPlayingInfo(tour: tour, waypoint: waypoint)
        } else {
            // No content audio — skip to nav or compass
            onContentFinished()
        }
    }

    private func onContentFinished() {
        guard let tour = activeTour, let waypoint = currentWaypoint else { return }

        if isLastStop {
            playbackMode = .finished
            isPlaying = false
            updateNowPlayingPlaybackState()
            return
        }

        // Try to play nav instruction
        if let navURL = storage.resolveNavAudioURL(tour: tour, waypoint: waypoint) {
            playbackMode = .navInstruction
            playAudio(url: navURL)
        } else {
            enterCompassMode()
        }
    }

    private func onNavInstructionFinished() {
        enterCompassMode()
    }

    private func enterCompassMode() {
        playbackMode = .compass
        isPlaying = false
        player.replaceCurrentItem(with: nil)
        fetchWalkingRoute()
    }

    private func advanceToNextStop() {
        guard let tour = activeTour else { return }
        let next = currentWaypointIndex + 1
        guard next < tour.waypoints.count else {
            playbackMode = .finished
            return
        }
        currentWaypointIndex = next
        walkingRoute = nil
        playContentAudio()
    }

    // MARK: - Audio playback

    private func playAudio(url: URL) {
        removePlayerEndObserver()
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
        startProgressTimer()

        playerEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onAudioFinished()
            }
        }
    }

    private func onAudioFinished() {
        stopProgressTimer()
        switch playbackMode {
        case .listening:
            onContentFinished()
        case .navInstruction:
            onNavInstructionFinished()
        case .compass, .finished:
            break
        }
    }

    private func removePlayerEndObserver() {
        if let observer = playerEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playerEndObserver = nil
        }
    }

    // MARK: - Progress tracking

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioCurrentTime = self.player.currentTime().seconds
                if let duration = self.player.currentItem?.duration.seconds, duration.isFinite {
                    self.audioDuration = duration
                }
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        audioCurrentTime = 0
        audioDuration = 0
    }

    // MARK: - Location polling + trigger circles

    private func startLocationPolling() {
        locationPollTimer?.invalidate()
        locationPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let location = self.locationService.currentLocation else { return }
                self.onLocationUpdate(location)
            }
        }
    }

    private func stopLocationPolling() {
        locationPollTimer?.invalidate()
        locationPollTimer = nil
    }

    private func onLocationUpdate(_ location: CLLocation) {
        guard let tour = activeTour else { return }
        let nextIndex = currentWaypointIndex + 1
        guard nextIndex < tour.waypoints.count else { return }

        let nextWp = tour.waypoints[nextIndex]
        let distance = location.distance(from: nextWp.clLocation)
        distanceToNextStop = distance

        // Calculate bearing
        bearingToNextStop = Self.bearing(
            from: location.coordinate,
            to: nextWp.coordinate
        )

        // Debug logging
        let tick = Int(Date().timeIntervalSince1970) % 10
        if tick == 0 {
            print("📍 Walking: \(String(format: "%.5f", location.coordinate.latitude)), \(String(format: "%.5f", location.coordinate.longitude)) → next [\(nextIndex)] \"\(nextWp.title)\" \(Int(distance))m (trigger: \(Int(nextWp.triggerRadiusMeters))m) mode: \(playbackMode)")
        }

        // Only auto-advance in compass mode (not while listening or playing nav)
        if playbackMode == .compass && distance <= nextWp.triggerRadiusMeters {
            print("🎯 Walking TRIGGERED: entering \"\(nextWp.title)\" at \(Int(distance))m")
            advanceToNextStop()
        }
    }

    // MARK: - Walking directions

    private func fetchWalkingRoute() {
        guard let current = locationService.currentLocation?.coordinate,
              let next = nextWaypoint?.coordinate else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: current))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: next))
        request.transportType = .walking

        let directions = MKDirections(request: request)
        Task { [weak self] in
            let response = try? await directions.calculate()
            await MainActor.run {
                if let route = response?.routes.first {
                    self?.walkingRoute = route
                }
            }
        }
    }

    /// Open Apple Maps with walking directions to the next waypoint.
    func openMapsToNextStop() {
        guard let wp = nextWaypoint else { return }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: wp.coordinate))
        destination.name = wp.title
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
        ])
    }

    // MARK: - Bearing calculation

    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLng = (to.longitude - from.longitude) * .pi / 180

        let y = sin(dLng) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    // MARK: - Audio session

    private func activateAudioSessionIfNeeded() {
        guard !sessionActivated else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            sessionActivated = true
        } catch {
            print("WalkingTourPlayer: failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        guard sessionActivated else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionActivated = false
        } catch {
            print("WalkingTourPlayer: failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Now Playing info

    private func updateNowPlayingInfo(tour: WalkingTour, waypoint: WalkingWaypoint) {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = waypoint.title
        info[MPMediaItemPropertyArtist] = tour.creatorName
        info[MPMediaItemPropertyAlbumTitle] = tour.title
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

        if let artwork = Self.makePlaceholderArtwork(title: tour.title, mode: tour.mode) {
            let image = artwork
            let size = artwork.size
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: size) { @Sendable _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private static func makePlaceholderArtwork(title: String, mode: TourMode) -> UIImage? {
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Different colors for different modes
            let color: UIColor = switch mode {
            case .walking: UIColor(red: 0.13, green: 0.36, blue: 0.28, alpha: 1.0) // forest green
            case .biking: UIColor(red: 0.20, green: 0.30, blue: 0.42, alpha: 1.0) // steel blue
            case .driving: UIColor(red: 0.10, green: 0.18, blue: 0.32, alpha: 1.0) // indigo
            }
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let para = NSMutableParagraphStyle()
            para.alignment = .center
            para.lineBreakMode = .byWordWrapping

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: para,
            ]
            let inset: CGFloat = 40
            let textRect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
            (title as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }

    // MARK: - Remote commands

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

// MARK: - CLLocationManagerDelegate (heading updates)

extension WalkingTourPlayer: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading
        Task { @MainActor in
            self.currentHeading = heading
        }
    }
}
