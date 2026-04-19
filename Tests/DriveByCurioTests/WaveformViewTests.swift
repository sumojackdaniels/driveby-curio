import XCTest
@testable import DriveByCurio

final class WaveformViewTests: XCTestCase {

    // MARK: - fraction(forX:width:)

    func testFractionAtLeftEdgeIsZero() {
        XCTAssertEqual(WaveformView.fraction(forX: 0, width: 100), 0.0, accuracy: 0.0001)
    }

    func testFractionAtRightEdgeIsOne() {
        XCTAssertEqual(WaveformView.fraction(forX: 100, width: 100), 1.0, accuracy: 0.0001)
    }

    func testFractionAtMidpointIsHalf() {
        XCTAssertEqual(WaveformView.fraction(forX: 50, width: 100), 0.5, accuracy: 0.0001)
    }

    func testFractionClampsNegativeXToZero() {
        XCTAssertEqual(WaveformView.fraction(forX: -10, width: 100), 0.0, accuracy: 0.0001)
    }

    func testFractionClampsOverflowXToOne() {
        XCTAssertEqual(WaveformView.fraction(forX: 150, width: 100), 1.0, accuracy: 0.0001)
    }

    func testFractionReturnsZeroForZeroWidth() {
        // Defensive: a zero-width waveform shouldn't divide by zero.
        XCTAssertEqual(WaveformView.fraction(forX: 10, width: 0), 0.0, accuracy: 0.0001)
    }

    func testFractionReturnsZeroForNegativeWidth() {
        // Defensive: negative width (shouldn't happen, but don't crash).
        XCTAssertEqual(WaveformView.fraction(forX: 10, width: -50), 0.0, accuracy: 0.0001)
    }

    func testFractionIsMonotonic() {
        // Monotonic within [0, width]: increasing x gives non-decreasing fraction.
        var previous = WaveformView.fraction(forX: 0, width: 200)
        for x in stride(from: 0, through: 200, by: 10) {
            let f = WaveformView.fraction(forX: CGFloat(x), width: 200)
            XCTAssertGreaterThanOrEqual(f, previous, "fraction should be non-decreasing at x=\(x)")
            previous = f
        }
    }
}
