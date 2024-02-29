import XCTest
@testable import VidEngine

final class VidEngineTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    func testBundle() {
        XCTAssertNotNil(VidBundle.metallib)
        XCTAssertNotNil(VidBundle.imageSquareFrame)
        XCTAssertNotNil(VidBundle.imageMeasureGrid)
        XCTAssertNotNil(VidBundle.rawCC14)
    }
}
