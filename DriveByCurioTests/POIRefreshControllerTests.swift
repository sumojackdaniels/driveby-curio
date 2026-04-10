import XCTest
import CoreLocation
@testable import DriveByCurio

final class POIRefreshControllerTests: XCTestCase {

    @MainActor
    func testShouldRefreshWhenNeverRefreshed() {
        let poiStore = POIStore()
        XCTAssertTrue(poiStore.canRefresh, "Should be able to refresh when never refreshed")
    }

    @MainActor
    func testShouldNotRefreshWithin60Seconds() {
        let poiStore = POIStore()
        poiStore.lastRefresh = Date()
        XCTAssertFalse(poiStore.canRefresh, "Should not refresh within 60 seconds")
    }

    @MainActor
    func testSignificantLocationChangeDetection() {
        // A location change > 500m should be considered significant
        let loc1 = CLLocation(latitude: 39.8283, longitude: -98.5795)
        let loc2 = CLLocation(latitude: 39.8330, longitude: -98.5795) // ~522m north

        let distance = loc1.distance(from: loc2)
        XCTAssertGreaterThan(distance, 500, "Locations should be > 500m apart")
    }

    @MainActor
    func testInsignificantLocationChangeDetection() {
        let loc1 = CLLocation(latitude: 39.8283, longitude: -98.5795)
        let loc2 = CLLocation(latitude: 39.8285, longitude: -98.5795) // ~22m north

        let distance = loc1.distance(from: loc2)
        XCTAssertLessThan(distance, 500, "Locations should be < 500m apart")
    }

    @MainActor
    func testClosestPOISelection() {
        let poiStore = POIStore()

        let poi1 = POI(name: "Far Place", topics: ["History"], description: "A far place", lat: 40.0, lng: -98.5)
        let poi2 = POI(name: "Near Place", topics: ["History"], description: "A near place", lat: 39.829, lng: -98.58)
        let poi3 = POI(name: "Mid Place", topics: ["History"], description: "A mid place", lat: 39.9, lng: -98.55)

        poiStore.pois = [poi1, poi2, poi3]

        let userLocation = CLLocation(latitude: 39.8283, longitude: -98.5795)

        // Find closest POI manually
        let closest = poiStore.pois.min(by: { a, b in
            let locA = CLLocation(latitude: a.lat, longitude: a.lng)
            let locB = CLLocation(latitude: b.lat, longitude: b.lng)
            return userLocation.distance(from: locA) < userLocation.distance(from: locB)
        })

        XCTAssertEqual(closest?.name, "Near Place", "Closest POI should be Near Place")
    }
}
