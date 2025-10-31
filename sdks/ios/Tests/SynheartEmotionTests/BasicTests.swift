import XCTest
@testable import SynheartEmotion

final class SynheartEmotionTests: XCTestCase {
    func testEngineCreation() {
        let config = EmotionConfig()
        let engine = try! EmotionEngine.fromPretrained(config: config)
        XCTAssertNotNil(engine)
    }
}
