import XCTest
@testable import DriveByCurio

final class StopStateTests: XCTestCase {

    // MARK: - Pre-start (no active tour)

    func testFirstStopIsArrivedWhenTourNotActive() {
        let state = StopTimelineRow.StopState.resolve(
            index: 0,
            isPlayerActive: false,
            playerStopIndex: 0,
            transitFromIndex: -1,
            playbackMode: .listening,
            isPlaying: false,
            hasStarted: false
        )
        XCTAssertEqual(state, .arrived, "First stop should pulse green pre-start to invite Play")
    }

    func testSubsequentStopsArePendingWhenTourNotActive() {
        for i in 1..<5 {
            let state = StopTimelineRow.StopState.resolve(
                index: i,
                isPlayerActive: false,
                playerStopIndex: 0,
                transitFromIndex: -1,
                playbackMode: .listening,
                isPlaying: false,
                hasStarted: false
            )
            XCTAssertEqual(state, .pending, "Stop \(i) should be pending pre-start")
        }
    }

    // MARK: - Active tour, not in transit

    func testStopBeforeCurrentIsDone() {
        let state = StopTimelineRow.StopState.resolve(
            index: 0,
            isPlayerActive: true,
            playerStopIndex: 2,
            transitFromIndex: -1,
            playbackMode: .listening,
            isPlaying: true,
            hasStarted: true
        )
        XCTAssertEqual(state, .done)
    }

    func testCurrentStopIsPlayingWhenListeningAndPlaying() {
        let state = StopTimelineRow.StopState.resolve(
            index: 1,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: -1,
            playbackMode: .listening,
            isPlaying: true,
            hasStarted: true
        )
        XCTAssertEqual(state, .playing)
    }

    func testCurrentStopIsArrivedWhenListeningButPaused() {
        let state = StopTimelineRow.StopState.resolve(
            index: 1,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: -1,
            playbackMode: .listening,
            isPlaying: false,
            hasStarted: true
        )
        XCTAssertEqual(state, .arrived)
    }

    func testCurrentStopIsCurrentWhenPlayingNavInstruction() {
        let state = StopTimelineRow.StopState.resolve(
            index: 1,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: -1,
            playbackMode: .navInstruction,
            isPlaying: true,
            hasStarted: true
        )
        XCTAssertEqual(state, .current)
    }

    func testStopAfterCurrentIsPending() {
        let state = StopTimelineRow.StopState.resolve(
            index: 3,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: -1,
            playbackMode: .listening,
            isPlaying: true,
            hasStarted: true
        )
        XCTAssertEqual(state, .pending)
    }

    // MARK: - Active tour, in transit

    func testTransitFromStopMarksPriorStopsDone() {
        let state = StopTimelineRow.StopState.resolve(
            index: 0,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: 1,
            playbackMode: .compass,
            isPlaying: false,
            hasStarted: true
        )
        XCTAssertEqual(state, .done)
    }

    func testTransitFromStopItselfIsDone() {
        let state = StopTimelineRow.StopState.resolve(
            index: 1,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: 1,
            playbackMode: .compass,
            isPlaying: false,
            hasStarted: true
        )
        XCTAssertEqual(state, .done)
    }

    func testNextStopAfterTransitIsApproaching() {
        let state = StopTimelineRow.StopState.resolve(
            index: 2,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: 1,
            playbackMode: .compass,
            isPlaying: false,
            hasStarted: true
        )
        XCTAssertEqual(state, .approaching)
    }

    func testStopsBeyondApproachingArePending() {
        let state = StopTimelineRow.StopState.resolve(
            index: 3,
            isPlayerActive: true,
            playerStopIndex: 1,
            transitFromIndex: 1,
            playbackMode: .compass,
            isPlaying: false,
            hasStarted: true
        )
        XCTAssertEqual(state, .pending)
    }
}
