import Foundation

public struct IngredientMetrics: Codable, Equatable, Sendable {
    public var caffeineMG: Double
    public var sugarG: Double
    public var caloriesKcal: Double
    public var hydrationML: Double

    public init(caffeineMG: Double = 0, sugarG: Double = 0, caloriesKcal: Double = 0, hydrationML: Double = 0) {
        self.caffeineMG = caffeineMG
        self.sugarG = sugarG
        self.caloriesKcal = caloriesKcal
        self.hydrationML = hydrationML
    }
}

public struct HealthGoals: Codable, Equatable, Sendable {
    public var caffeineLimitMG: Double
    public var sugarLimitG: Double
    public var caloriesLimitKcal: Double
    public var hydrationGoalML: Double

    public init(
        caffeineLimitMG: Double = 300,
        sugarLimitG: Double = 25,
        caloriesLimitKcal: Double = 1800,
        hydrationGoalML: Double = 2000
    ) {
        self.caffeineLimitMG = caffeineLimitMG
        self.sugarLimitG = sugarLimitG
        self.caloriesLimitKcal = caloriesLimitKcal
        self.hydrationGoalML = hydrationGoalML
    }
}

public struct DailyAggregate: Codable, Equatable, Sendable {
    public var totals: IngredientMetrics
    public var entryCount: Int

    public init(totals: IngredientMetrics, entryCount: Int) {
        self.totals = totals
        self.entryCount = entryCount
    }
}

public struct RecommendationExplanation: Codable, Equatable, Sendable {
    public var ruleID: String
    public var trigger: String
    public var thresholdComparison: String
    public var action: String
    public var risk: String

    public init(ruleID: String, trigger: String, thresholdComparison: String, action: String, risk: String) {
        self.ruleID = ruleID
        self.trigger = trigger
        self.thresholdComparison = thresholdComparison
        self.action = action
        self.risk = risk
    }
}

public struct RecommendationDecision: Codable, Equatable, Sendable {
    public var severity: Severity
    public var title: String
    public var summary: String
    public var explanation: RecommendationExplanation

    public enum Severity: String, Codable, Equatable, Sendable {
        case info
        case warning
        case critical
    }

    public init(severity: Severity, title: String, summary: String, explanation: RecommendationExplanation) {
        self.severity = severity
        self.title = title
        self.summary = summary
        self.explanation = explanation
    }
}

public struct MetricProgress: Equatable, Sendable {
    public var label: String
    public var consumed: Double
    public var target: Double
    public var ratio: Double

    public init(label: String, consumed: Double, target: Double, ratio: Double) {
        self.label = label
        self.consumed = consumed
        self.target = target
        self.ratio = ratio
    }
}

public enum DailyHealthEvaluator {
    public static func progress(aggregate: DailyAggregate, goals: HealthGoals) -> [MetricProgress] {
        [
            MetricProgress(
                label: "咖啡因",
                consumed: aggregate.totals.caffeineMG,
                target: goals.caffeineLimitMG,
                ratio: safeRatio(aggregate.totals.caffeineMG, goals.caffeineLimitMG)
            ),
            MetricProgress(
                label: "糖分",
                consumed: aggregate.totals.sugarG,
                target: goals.sugarLimitG,
                ratio: safeRatio(aggregate.totals.sugarG, goals.sugarLimitG)
            ),
            MetricProgress(
                label: "补水",
                consumed: aggregate.totals.hydrationML,
                target: goals.hydrationGoalML,
                ratio: safeRatio(aggregate.totals.hydrationML, goals.hydrationGoalML)
            ),
        ]
    }

    public static func headline(for decisions: [RecommendationDecision]) -> String {
        guard let primary = decisions.sorted(by: severityRank).first else {
            return "今日状态稳定"
        }
        return primary.title
    }

    public static func summary(aggregate: DailyAggregate, goals: HealthGoals) -> String {
        let caffeine = safeRatio(aggregate.totals.caffeineMG, goals.caffeineLimitMG)
        let sugar = safeRatio(aggregate.totals.sugarG, goals.sugarLimitG)
        if caffeine >= 1 || sugar >= 1 {
            return "至少一项关键摄入已超过目标，建议立即调整后续饮品选择。"
        }
        if caffeine >= 0.8 || sugar >= 0.8 {
            return "关键摄入接近预警线，今天剩余时间适合选择更轻的饮品。"
        }
        return "目前摄入仍在合理区间，可以继续保持节奏。"
    }

    private static func safeRatio(_ value: Double, _ target: Double) -> Double {
        guard target > 0 else { return 0 }
        return value / target
    }

    private static func severityRank(
        lhs: RecommendationDecision,
        rhs: RecommendationDecision
    ) -> Bool {
        rank(lhs.severity) > rank(rhs.severity)
    }

    private static func rank(_ severity: RecommendationDecision.Severity) -> Int {
        switch severity {
        case .critical:
            return 3
        case .warning:
            return 2
        case .info:
            return 1
        }
    }
}
