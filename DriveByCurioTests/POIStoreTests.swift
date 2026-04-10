import XCTest
@testable import DriveByCurio

final class POIStoreTests: XCTestCase {
    @MainActor
    func testCanRefreshWhenNeverRefreshed() async {
        let store = POIStore()
        XCTAssertTrue(store.canRefresh)
        print("✓ canRefresh is true when never refreshed")
    }

    @MainActor
    func testCannotRefreshWithin60Seconds() async {
        let store = POIStore()
        store.lastRefresh = Date()
        XCTAssertFalse(store.canRefresh)
        print("✓ canRefresh is false within 60s")
    }

    @MainActor
    func testCanRefreshAfter60Seconds() async {
        let store = POIStore()
        store.lastRefresh = Date(timeIntervalSinceNow: -61)
        XCTAssertTrue(store.canRefresh)
        print("✓ canRefresh is true after 60s")
    }
}
