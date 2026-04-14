import XCTest
@testable import YinzhiCore

final class YinzhiCoreTests: XCTestCase {
    func testProgressRatiosReflectGoals() {
        let aggregate = DailyAggregate(
            totals: IngredientMetrics(caffeineMG: 240, sugarG: 20, caloriesKcal: 320, hydrationML: 900),
            entryCount: 2
        )
        let goals = HealthGoals(caffeineLimitMG: 300, sugarLimitG: 25, caloriesLimitKcal: 1800, hydrationGoalML: 2000)

        let progress = DailyHealthEvaluator.progress(aggregate: aggregate, goals: goals)

        XCTAssertEqual(progress[0].ratio, 0.8, accuracy: 0.0001)
        XCTAssertEqual(progress[1].ratio, 0.8, accuracy: 0.0001)
        XCTAssertEqual(progress[2].ratio, 0.45, accuracy: 0.0001)
    }

    func testHeadlinePrefersHighestSeverityDecision() {
        let info = RecommendationDecision(
            severity: .info,
            title: "节奏稳定",
            summary: "",
            explanation: RecommendationExplanation(
                ruleID: "within-range",
                trigger: "",
                thresholdComparison: "",
                action: "",
                risk: ""
            )
        )
        let critical = RecommendationDecision(
            severity: .critical,
            title: "糖分过高",
            summary: "",
            explanation: RecommendationExplanation(
                ruleID: "sugar-warning",
                trigger: "",
                thresholdComparison: "",
                action: "",
                risk: ""
            )
        )

        XCTAssertEqual(DailyHealthEvaluator.headline(for: [info, critical]), "糖分过高")
    }

    func testSummaryWarnsWhenThresholdIsExceeded() {
        let aggregate = DailyAggregate(
            totals: IngredientMetrics(caffeineMG: 320, sugarG: 12, caloriesKcal: 180, hydrationML: 400),
            entryCount: 1
        )
        let goals = HealthGoals(caffeineLimitMG: 300, sugarLimitG: 25, caloriesLimitKcal: 1800, hydrationGoalML: 2000)

        let summary = DailyHealthEvaluator.summary(aggregate: aggregate, goals: goals)

        XCTAssertTrue(summary.contains("超过目标"))
    }
}
