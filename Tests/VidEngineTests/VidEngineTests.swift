import Testing
@testable import VidEngine

// Ref. https://leocoout.medium.com/welcome-swift-testing-goodbye-xctest-7501b7a5b304

struct VidEngineTests {
    @Test("Make sure all the necessary bundles are present")
    func testBundle() {
        #expect(VidBundle.metallib != nil)
        #expect(VidBundle.imageSquareFrame != nil)
        #expect(VidBundle.imageMeasureGrid != nil)
        #expect(VidBundle.rawCC14 != nil)
    }
}
