import XCTest
import CoreLocation
@testable import DriveByCurio

final class AudioAnnouncementTests: XCTestCase {

    @MainActor
    func testAnnouncedPOIIsTracked() {
        let service = AudioAnnouncementService()
        let poi = POI(name: "Test Place", topics: ["History"], description: "A test place.", lat: 39.8, lng: -77.2)

        XCTAssertFalse(service.hasAnnounced(poi), "POI should not be announced yet")
        service.markAnnounced(poi)
        XCTAssertTrue(service.hasAnnounced(poi), "POI should be marked as announced")
    }

    @MainActor
    func testShouldNotAnnounceBeyond2km() {
        let service = AudioAnnouncementService()
        let poi = POI(name: "Distant Place", topics: ["History"], description: "Too far.", lat: 40.0, lng: -77.2)
        let userLocation = CLLocation(latitude: 39.8, longitude: -77.2)

        let distance = userLocation.distance(from: CLLocation(latitude: poi.lat, longitude: poi.lng))
        XCTAssertGreaterThan(distance, 2000, "POI should be > 2km away")
        XCTAssertFalse(service.shouldAnnounce(poi, userLocation: userLocation), "Should not announce POI > 2km away")
    }

    @MainActor
    func testShouldAnnounceNearbyNewPOI() {
        let service = AudioAnnouncementService()
        let poi = POI(name: "Nearby Place", topics: ["History"], description: "Close by.", lat: 39.801, lng: -77.2)
        let userLocation = CLLocation(latitude: 39.8, longitude: -77.2)

        let distance = userLocation.distance(from: CLLocation(latitude: poi.lat, longitude: poi.lng))
        XCTAssertLessThan(distance, 2000, "POI should be < 2km away")
        XCTAssertTrue(service.shouldAnnounce(poi, userLocation: userLocation), "Should announce nearby new POI")
    }

    @MainActor
    func testShouldNotReannounce() {
        let service = AudioAnnouncementService()
        let poi = POI(name: "Already Heard", topics: ["History"], description: "Heard this.", lat: 39.801, lng: -77.2)
        let userLocation = CLLocation(latitude: 39.8, longitude: -77.2)

        service.markAnnounced(poi)
        XCTAssertFalse(service.shouldAnnounce(poi, userLocation: userLocation), "Should not re-announce already announced POI")
    }
}
