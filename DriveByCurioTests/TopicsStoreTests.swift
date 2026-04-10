import XCTest
@testable import DriveByCurio

final class TopicsStoreTests: XCTestCase {
    @MainActor
    func testParsedTopicsFromMultilineText() {
        let store = TopicsStore()
        store.topicsText = "Civil War History\nRock and Roll\n\nNative American Heritage"
        XCTAssertEqual(store.parsedTopics, ["Civil War History", "Rock and Roll", "Native American Heritage"])
        print("✓ parsedTopics splits and filters correctly")
    }

    @MainActor
    func testEmptyTextReturnsNoTopics() {
        let store = TopicsStore()
        store.topicsText = ""
        XCTAssertTrue(store.parsedTopics.isEmpty)
        print("✓ empty text returns no topics")
    }

    @MainActor
    func testWhitespaceOnlyLinesFiltered() {
        let store = TopicsStore()
        store.topicsText = "  \n  Topic One  \n   \n"
        XCTAssertEqual(store.parsedTopics, ["Topic One"])
        print("✓ whitespace-only lines filtered out")
    }
}
