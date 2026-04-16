import XCTest
@testable import Yinzhi

final class QuickCaptureTests: XCTestCase {
    func testQuickCapturePrefersBrandAndDrinkName() {
        let result = QuickCaptureRecognizer.buildResult(
            recognizedText: "MANNER 燕麦拿铁 320ml",
            source: .library,
            catalog: PreviewFixtures.drinks
        )

        XCTAssertEqual(result.matches.first?.drink.id, "latte-oat")
        XCTAssertTrue(result.matches.first?.matchedTerms.contains("MANNER") == true)
    }

    func testQuickCaptureRecognizesHandBrewKeywords() {
        let result = QuickCaptureRecognizer.buildResult(
            recognizedText: "Blue Bottle V60 耶加雪菲 手冲",
            source: .camera,
            catalog: PreviewFixtures.drinks
        )

        XCTAssertEqual(result.matches.first?.drink.id, "pour-over-yirgacheffe")
        XCTAssertTrue(result.matches.first?.matchedTerms.contains("手冲") == true || result.matches.first?.matchedTerms.contains("V60") == true)
    }

    func testQuickCaptureFallsBackToSuggestedQueryWhenNoCatalogMatch() {
        let result = QuickCaptureRecognizer.buildResult(
            recognizedText: "生椰轻乳茶 冰杯",
            source: .library,
            catalog: PreviewFixtures.drinks
        )

        XCTAssertTrue(result.matches.isEmpty)
        XCTAssertTrue(result.suggestedQuery.contains("生椰"))
    }

    func testQuickCaptureSupportsVoiceStyleSentence() {
        let result = QuickCaptureRecognizer.buildResult(
            recognizedText: "我刚刚喝了一杯瑞幸冰美式大杯",
            source: .voice,
            catalog: PreviewFixtures.drinks
        )

        XCTAssertEqual(result.matches.first?.drink.id, "americano-iced")
        XCTAssertEqual(result.source, .voice)
    }
}
