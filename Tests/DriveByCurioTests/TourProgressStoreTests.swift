import XCTest
@testable import DriveByCurio

@MainActor
final class TourProgressStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "TourProgressStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeStore() -> TourProgressStore {
        TourProgressStore(defaults: defaults)
    }

    // MARK: - Save / retrieve

    func testSaveThenRetrieve() {
        let store = makeStore()
        let progress = TourProgress(
            tourId: "tour-a",
            stopIndex: 2,
            segmentIndex: 1,
            audioTime: 42.5,
            savedAt: Date(timeIntervalSince1970: 1000)
        )

        store.save(progress)

        XCTAssertEqual(store.progress(for: "tour-a"), progress)
    }

    func testRetrieveReturnsNilForUnknownTour() {
        let store = makeStore()
        XCTAssertNil(store.progress(for: "does-not-exist"))
    }

    func testSaveOverwritesExistingProgressForSameTour() {
        let store = makeStore()
        let original = TourProgress(tourId: "t", stopIndex: 0, segmentIndex: 0, audioTime: 0, savedAt: Date(timeIntervalSince1970: 0))
        let updated = TourProgress(tourId: "t", stopIndex: 4, segmentIndex: 2, audioTime: 120, savedAt: Date(timeIntervalSince1970: 100))

        store.save(original)
        store.save(updated)

        XCTAssertEqual(store.progress(for: "t"), updated)
        XCTAssertEqual(store.progressByTour.count, 1)
    }

    // MARK: - Multiple tours

    func testProgressForDifferentToursIsIndependent() {
        let store = makeStore()
        let a = TourProgress(tourId: "a", stopIndex: 1, segmentIndex: 0, audioTime: 10, savedAt: Date(timeIntervalSince1970: 1))
        let b = TourProgress(tourId: "b", stopIndex: 3, segmentIndex: 1, audioTime: 50, savedAt: Date(timeIntervalSince1970: 2))

        store.save(a)
        store.save(b)

        XCTAssertEqual(store.progress(for: "a"), a)
        XCTAssertEqual(store.progress(for: "b"), b)
    }

    // MARK: - Clear

    func testClearRemovesSpecificTour() {
        let store = makeStore()
        let a = TourProgress(tourId: "a", stopIndex: 1, segmentIndex: 0, audioTime: 10, savedAt: Date(timeIntervalSince1970: 1))
        let b = TourProgress(tourId: "b", stopIndex: 3, segmentIndex: 1, audioTime: 50, savedAt: Date(timeIntervalSince1970: 2))
        store.save(a)
        store.save(b)

        store.clear(tourId: "a")

        XCTAssertNil(store.progress(for: "a"))
        XCTAssertEqual(store.progress(for: "b"), b)
    }

    func testClearAllRemovesEverything() {
        let store = makeStore()
        store.save(TourProgress(tourId: "a", stopIndex: 1, segmentIndex: 0, audioTime: 10, savedAt: Date()))
        store.save(TourProgress(tourId: "b", stopIndex: 3, segmentIndex: 1, audioTime: 50, savedAt: Date()))

        store.clearAll()

        XCTAssertTrue(store.progressByTour.isEmpty)
    }

    // MARK: - Persistence

    func testPersistsAcrossInstances() {
        let writer = makeStore()
        let progress = TourProgress(
            tourId: "tour-a",
            stopIndex: 2,
            segmentIndex: 1,
            audioTime: 42.5,
            savedAt: Date(timeIntervalSince1970: 1000)
        )
        writer.save(progress)

        let reader = makeStore()
        XCTAssertEqual(reader.progress(for: "tour-a"), progress)
    }

    func testNewInstanceIsEmptyWhenNoPriorData() {
        let store = makeStore()
        XCTAssertTrue(store.progressByTour.isEmpty)
    }
}
