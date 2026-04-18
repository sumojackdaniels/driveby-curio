import XCTest
@testable import DriveByCurio

final class WalkingTourTests: XCTestCase {

    // MARK: - coverQuote

    func testCoverQuoteStripsTrailingPeriodWhenDescriptionEndsInPeriod() {
        let tour = makeTour(description: "A quiet walk through the gardens.")
        XCTAssertEqual(tour.coverQuote, "A quiet walk through the gardens")
    }

    func testCoverQuoteTakesFirstSentenceWhenMultipleSentences() {
        let tour = makeTour(description: "A quiet walk. Bring water.")
        XCTAssertEqual(tour.coverQuote, "A quiet walk")
    }

    func testCoverQuoteReturnsFullDescriptionWhenNoPeriod() {
        let tour = makeTour(description: "Quick loop")
        XCTAssertEqual(tour.coverQuote, "Quick loop")
    }

    func testCoverQuoteHandlesEmptyDescription() {
        let tour = makeTour(description: "")
        XCTAssertEqual(tour.coverQuote, "")
    }

    // MARK: - computePaths

    func testComputePathsReturnsEmptyForZeroStops() {
        XCTAssertEqual(WalkingTour.computePaths(from: []), [])
    }

    func testComputePathsReturnsEmptyForSingleStop() {
        let stops = [makeStop(id: "a", order: 1, lat: 38.99, lng: -77.10)]
        XCTAssertEqual(WalkingTour.computePaths(from: stops), [])
    }

    func testComputePathsReturnsOnePathForTwoStops() {
        let stops = [
            makeStop(id: "a", order: 1, lat: 38.99000, lng: -77.10000),
            makeStop(id: "b", order: 2, lat: 38.99500, lng: -77.10000),
        ]
        let paths = WalkingTour.computePaths(from: stops)
        XCTAssertEqual(paths.count, 1)
        // ~0.5 minutes of latitude ≈ 556m ≈ 1824 ft.
        XCTAssertGreaterThan(paths[0].distanceFeet, 1700)
        XCTAssertLessThan(paths[0].distanceFeet, 1900)
        XCTAssertGreaterThanOrEqual(paths[0].walkMinutes, 1)
        XCTAssertGreaterThanOrEqual(paths[0].bikeMinutes, 1)
    }

    func testComputePathsSortsByOrderBeforeComputing() {
        // Stops provided in an insertion order that differs from .order.
        // Sorted-by-order latitudes are 38.97 → 38.99 → 39.00 (legs 0.02, 0.01).
        // Insertion-order latitudes are 38.99 → 38.97 → 39.00 (legs 0.02, 0.03).
        // A correct sort-then-pair gives paths[0] > paths[1].
        // A buggy implementation that zips insertion order gives paths[0] < paths[1].
        let stops = [
            makeStop(id: "b", order: 2, lat: 38.99, lng: -77.10),
            makeStop(id: "a", order: 1, lat: 38.97, lng: -77.10),
            makeStop(id: "c", order: 3, lat: 39.00, lng: -77.10),
        ]
        let paths = WalkingTour.computePaths(from: stops)
        XCTAssertEqual(paths.count, 2)
        XCTAssertGreaterThan(paths[0].distanceFeet, paths[1].distanceFeet,
                             "paths[0] (a→b, 0.02°) should be longer than paths[1] (b→c, 0.01°) if sort worked")
    }

    func testComputePathsMinimumOneMinuteForShortLeg() {
        // Two points a few feet apart — walk/bike minutes must still be >= 1.
        let stops = [
            makeStop(id: "a", order: 1, lat: 38.99000, lng: -77.10000),
            makeStop(id: "b", order: 2, lat: 38.99001, lng: -77.10001),
        ]
        let paths = WalkingTour.computePaths(from: stops)
        XCTAssertEqual(paths.count, 1)
        XCTAssertGreaterThanOrEqual(paths[0].walkMinutes, 1)
        XCTAssertGreaterThanOrEqual(paths[0].bikeMinutes, 1)
    }

    // MARK: - Legacy JSON migration

    func testDecodeLegacyWaypointFormatProducesStopsAndPaths() throws {
        let legacyJSON = """
        {
          "id": "legacy-tour-1",
          "title": "Legacy Tour",
          "creatorName": "Old Author",
          "creatorIsLocal": true,
          "description": "A tour in the old format.",
          "tags": ["history"],
          "mode": "walking",
          "waypoints": [
            {
              "id": "wp-1",
              "order": 1,
              "lat": 38.99000,
              "lng": -77.10000,
              "title": "First Stop",
              "description": "Start here.",
              "triggerRadiusMeters": 30,
              "contentAudioFile": "content.m4a",
              "navAudioFile": null,
              "narrationText": "Welcome.",
              "navInstructionText": null
            },
            {
              "id": "wp-2",
              "order": 2,
              "lat": 38.99500,
              "lng": -77.10000,
              "title": "Second Stop",
              "description": "Next one.",
              "triggerRadiusMeters": 30,
              "contentAudioFile": "content.m4a",
              "navAudioFile": "nav.m4a",
              "narrationText": "Onward.",
              "navInstructionText": "Walk north."
            }
          ],
          "createdAt": 1744761600,
          "updatedAt": 1744761600,
          "isAuthored": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let tour = try decoder.decode(WalkingTour.self, from: legacyJSON)

        XCTAssertEqual(tour.id, "legacy-tour-1")
        XCTAssertEqual(tour.title, "Legacy Tour")
        XCTAssertEqual(tour.author.name, "Old Author")
        XCTAssertEqual(tour.author.role, "Local guide")
        XCTAssertEqual(tour.stops.count, 2)

        let first = tour.stops[0]
        XCTAssertEqual(first.id, "wp-1")
        XCTAssertEqual(first.title, "First Stop")
        XCTAssertEqual(first.address, "Start here.")
        XCTAssertEqual(first.segments.count, 1)
        XCTAssertEqual(first.segments[0].kind, .narration)
        XCTAssertEqual(first.segments[0].audioFile, "content.m4a")
        XCTAssertEqual(first.segments[0].narrationText, "Welcome.")

        // Paths should be computed from GPS since legacy format has no paths.
        XCTAssertEqual(tour.paths.count, 1)
        XCTAssertGreaterThan(tour.paths[0].distanceFeet, 0)
    }

    func testDecodeLegacyNonLocalAuthorGetsGenericRole() throws {
        let legacyJSON = """
        {
          "id": "t",
          "title": "T",
          "creatorName": "Stranger",
          "creatorIsLocal": false,
          "description": "",
          "tags": [],
          "mode": "walking",
          "waypoints": [],
          "createdAt": 0,
          "updatedAt": 0,
          "isAuthored": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let tour = try decoder.decode(WalkingTour.self, from: legacyJSON)
        XCTAssertEqual(tour.author.role, "Guide")
        XCTAssertTrue(tour.stops.isEmpty)
        XCTAssertTrue(tour.paths.isEmpty)
    }

    func testEncodeThenDecodeRoundTripsNewFormat() throws {
        let original = makeTour(description: "Hello. World.")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(WalkingTour.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.author.name, original.author.name)
        XCTAssertEqual(decoded.stops.count, original.stops.count)
    }

    // MARK: - Helpers

    private func makeTour(description: String) -> WalkingTour {
        WalkingTour(
            id: "test-tour",
            title: "Test",
            author: TourAuthor(name: "Tester", role: "Local guide"),
            description: description,
            tags: [],
            mode: .walking,
            stops: [],
            paths: [],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            isAuthored: false
        )
    }

    private func makeStop(id: String, order: Int, lat: Double, lng: Double) -> TourStop {
        TourStop(
            id: id,
            order: order,
            title: id,
            description: "",
            address: "",
            lat: lat,
            lng: lng,
            triggerRadiusMeters: 30,
            segments: [],
            navAudioFile: nil,
            navInstructionText: nil
        )
    }
}
