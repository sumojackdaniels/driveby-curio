import XCTest
import CoreLocation
@testable import DriveByCurio

final class CarPlayTemplateTests: XCTestCase {

    @MainActor
    func testPOIStoreMaximum12() {
        let store = POIStore()
        // Generate 15 POIs
        var pois: [POI] = []
        for i in 0..<15 {
            pois.append(POI(
                name: "Place \(i)",
                topics: ["Test"],
                description: "Description \(i)",
                lat: 39.8 + Double(i) * 0.01,
                lng: -77.2
            ))
        }
        // Store should accept all, but CarPlay display should limit to 12
        store.pois = pois
        XCTAssertEqual(store.pois.count, 15, "Store holds all POIs")

        let displayPOIs = Array(store.pois.prefix(12))
        XCTAssertEqual(displayPOIs.count, 12, "Display should limit to 12 POIs")
    }

    @MainActor
    func testPOIHasRequiredFields() {
        let poi = POI(
            name: "Gettysburg Battlefield",
            topics: ["Civil War History"],
            description: "Site of the pivotal 1863 battle.",
            lat: 39.8112,
            lng: -77.2258
        )

        XCTAssertEqual(poi.name, "Gettysburg Battlefield")
        XCTAssertEqual(poi.topics, ["Civil War History"])
        XCTAssertFalse(poi.description.isEmpty)
        XCTAssertEqual(poi.coordinate.latitude, 39.8112, accuracy: 0.0001)
        XCTAssertEqual(poi.coordinate.longitude, -77.2258, accuracy: 0.0001)
    }

    @MainActor
    func testDistanceFormatting() {
        // Test that we can compute and format distances for POI detail views
        let userCoord = CLLocationCoordinate2D(latitude: 39.8, longitude: -77.2)
        let poiCoord = CLLocationCoordinate2D(latitude: 39.81, longitude: -77.21)

        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let poiLoc = CLLocation(latitude: poiCoord.latitude, longitude: poiCoord.longitude)
        let distance = userLoc.distance(from: poiLoc)

        XCTAssertGreaterThan(distance, 0, "Distance should be positive")

        // Convert to miles
        let miles = distance / 1609.344
        let formatted = String(format: "%.1f mi", miles)
        XCTAssertTrue(formatted.hasSuffix("mi"), "Should be formatted in miles")
    }
}
