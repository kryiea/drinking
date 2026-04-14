import Foundation

struct IngredientMetrics: Codable, Hashable, Sendable {
    var caffeineMG: Double
    var sugarG: Double
    var caloriesKcal: Double
    var hydrationML: Double
    var volumeML: Double

    init(
        caffeineMG: Double = 0,
        sugarG: Double = 0,
        caloriesKcal: Double = 0,
        hydrationML: Double = 0,
        volumeML: Double = 0
    ) {
        self.caffeineMG = caffeineMG
        self.sugarG = sugarG
        self.caloriesKcal = caloriesKcal
        self.hydrationML = hydrationML
        self.volumeML = volumeML
    }

    static let zero = IngredientMetrics()

    func adding(_ other: IngredientMetrics) -> IngredientMetrics {
        IngredientMetrics(
            caffeineMG: caffeineMG + other.caffeineMG,
            sugarG: sugarG + other.sugarG,
            caloriesKcal: caloriesKcal + other.caloriesKcal,
            hydrationML: hydrationML + other.hydrationML,
            volumeML: volumeML + other.volumeML
        )
    }

    func scaled(by ratio: Double) -> IngredientMetrics {
        IngredientMetrics(
            caffeineMG: caffeineMG * ratio,
            sugarG: sugarG * ratio,
            caloriesKcal: caloriesKcal * ratio,
            hydrationML: hydrationML * ratio,
            volumeML: volumeML * ratio
        )
    }
}

struct DrinkServingOption: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var volumeML: Int
    var multiplier: Double = 1.0
}

struct DrinkDefinitionSummary: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var category: String
    var brand: String
    var tags: [String]
    var metrics: IngredientMetrics
    var servingOptions: [DrinkServingOption]

    var preferredServing: DrinkServingOption {
        servingOptions.first ?? DrinkServingOption(id: "default", name: "标准份", volumeML: Int(metrics.volumeML))
    }
}

enum DrinkLogSource: String, Codable, Hashable, Sendable {
    case catalog
    case recent
    case favorite
    case custom
}

enum SyncState: String, Codable, Hashable, Sendable {
    case synced
    case pending
    case conflict
}

struct DrinkLogEntry: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var userID: String?
    var drinkDefinitionID: String?
    var drinkName: String
    var category: String
    var consumedAt: Date
    var servingLabel: String
    var metrics: IngredientMetrics
    var note: String?
    var source: DrinkLogSource
    var version: Int
    var syncStatus: SyncState

    init(
        id: String,
        userID: String? = nil,
        drinkDefinitionID: String? = nil,
        drinkName: String,
        category: String,
        consumedAt: Date,
        servingLabel: String,
        metrics: IngredientMetrics,
        note: String? = nil,
        source: DrinkLogSource,
        version: Int = 1,
        syncStatus: SyncState = .synced
    ) {
        self.id = id
        self.userID = userID
        self.drinkDefinitionID = drinkDefinitionID
        self.drinkName = drinkName
        self.category = category
        self.consumedAt = consumedAt
        self.servingLabel = servingLabel
        self.metrics = metrics
        self.note = note
        self.source = source
        self.version = version
        self.syncStatus = syncStatus
    }

    var isPendingSync: Bool {
        syncStatus != .synced
    }
}

struct RecommendationExplanation: Codable, Hashable, Sendable {
    var ruleID: String
    var trigger: String
    var inputs: [String: String]
    var thresholdComparison: String
    var action: String
    var risk: String
}

struct RecommendationCard: Identifiable, Codable, Hashable, Sendable {
    var id: String { ruleID + title }
    var ruleID: String
    var severity: String
    var title: String
    var summary: String
    var explanation: RecommendationExplanation
}

struct HealthGoalsSummary: Codable, Hashable, Sendable {
    var caffeineLimitMG: Double
    var sugarLimitG: Double
    var caloriesLimitKcal: Double
    var hydrationGoalML: Double
}

struct UserProfileSummary: Codable, Hashable, Sendable {
    var userID: String?
    var displayName: String
    var age: Int
    var sleepHourText: String
    var caffeineSensitive: Bool
    var bloodSugarWatch: Bool
}

struct CategoryBreakdownSummary: Identifiable, Codable, Hashable, Sendable {
    var id: String { category }
    var category: String
    var entriesCount: Int
    var hydrationML: Double
}

struct DailyAggregateSnapshot: Codable, Hashable, Sendable {
    var date: Date
    var totals: IngredientMetrics
    var entriesCount: Int
    var categoryBreakdown: [CategoryBreakdownSummary]
}

struct SyncEnvelopeSummary: Codable, Hashable, Sendable {
    var lastSyncedAt: Date?
    var pendingEntryIDs: [String]
    var conflictCount: Int

    var pendingCount: Int {
        pendingEntryIDs.count
    }
}

struct AppSession: Codable, Hashable, Sendable {
    var accessToken: String
    var tokenType: String
    var expiresIn: Int
    var userID: String
    var displayName: String
    var sync: SyncEnvelopeSummary
    var issuedAt: Date

    var isExpired: Bool {
        issuedAt.addingTimeInterval(TimeInterval(expiresIn)) < .now
    }
}

struct CreateDrinkLogInput: Codable, Hashable, Sendable {
    var drinkDefinitionID: String
    var servingOptionID: String?
    var ratio: Double
    var consumedAt: Date
    var note: String?
    var source: DrinkLogSource
}

struct DashboardState: Sendable {
    var date: Date
    var aggregate: IngredientMetrics
    var goals: HealthGoalsSummary
    var recommendations: [RecommendationCard]
    var todayEntries: [DrinkLogEntry]
    var categoryBreakdown: [CategoryBreakdownSummary]
}

enum AppTab: String, CaseIterable, Identifiable {
    case home = "首页"
    case log = "记录"
    case insights = "分析"
    case profile = "我的"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home:
            return "sparkles.rectangle.stack"
        case .log:
            return "plus.viewfinder"
        case .insights:
            return "chart.xyaxis.line"
        case .profile:
            return "person.crop.circle"
        }
    }
}

enum PreviewFixtures {
    static let goals = HealthGoalsSummary(
        caffeineLimitMG: 300,
        sugarLimitG: 25,
        caloriesLimitKcal: 1800,
        hydrationGoalML: 2000
    )

    static let profile = UserProfileSummary(
        userID: "preview-user",
        displayName: "饮知用户",
        age: 28,
        sleepHourText: "23:30",
        caffeineSensitive: false,
        bloodSugarWatch: true
    )

    static let drinks: [DrinkDefinitionSummary] = [
        DrinkDefinitionSummary(
            id: "latte-oat",
            name: "燕麦拿铁",
            category: "咖啡",
            brand: "饮知精选",
            tags: ["办公", "早餐"],
            metrics: IngredientMetrics(caffeineMG: 120, sugarG: 7, caloriesKcal: 145, hydrationML: 260, volumeML: 320),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 320, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "jasmine-milk-tea",
            name: "茉莉奶绿",
            category: "奶茶",
            brand: "饮知精选",
            tags: ["下午茶", "高糖"],
            metrics: IngredientMetrics(caffeineMG: 55, sugarG: 28, caloriesKcal: 265, hydrationML: 480, volumeML: 500),
            servingOptions: [.init(id: "half-sugar", name: "半糖", volumeML: 500, multiplier: 0.78)]
        ),
        DrinkDefinitionSummary(
            id: "sparkling-water",
            name: "青柠气泡水",
            category: "气泡饮",
            brand: "饮知精选",
            tags: ["低糖", "补水"],
            metrics: IngredientMetrics(caffeineMG: 0, sugarG: 1, caloriesKcal: 12, hydrationML: 330, volumeML: 330),
            servingOptions: [.init(id: "can", name: "一听", volumeML: 330, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "energy-shot",
            name: "能量饮料",
            category: "功能饮料",
            brand: "饮知精选",
            tags: ["加班", "高咖啡因"],
            metrics: IngredientMetrics(caffeineMG: 180, sugarG: 24, caloriesKcal: 165, hydrationML: 250, volumeML: 250),
            servingOptions: [.init(id: "bottle", name: "标准瓶", volumeML: 250, multiplier: 1.0)]
        ),
    ]

    static let entries: [DrinkLogEntry] = [
        DrinkLogEntry(
            id: "entry-1",
            userID: "preview-user",
            drinkDefinitionID: "latte-oat",
            drinkName: "燕麦拿铁",
            category: "咖啡",
            consumedAt: .now.addingTimeInterval(-60 * 60 * 3),
            servingLabel: "标准杯",
            metrics: IngredientMetrics(caffeineMG: 120, sugarG: 7, caloriesKcal: 145, hydrationML: 260, volumeML: 320),
            source: .catalog
        ),
        DrinkLogEntry(
            id: "entry-2",
            userID: "preview-user",
            drinkDefinitionID: "jasmine-milk-tea",
            drinkName: "茉莉奶绿",
            category: "奶茶",
            consumedAt: .now.addingTimeInterval(-60 * 35),
            servingLabel: "半糖",
            metrics: IngredientMetrics(caffeineMG: 42.9, sugarG: 21.84, caloriesKcal: 206.7, hydrationML: 374.4, volumeML: 390),
            source: .recent
        ),
    ]

    static let recommendations = buildRecommendations(
        aggregate: entries.reduce(into: .zero) { partialResult, entry in
            partialResult = partialResult.adding(entry.metrics)
        },
        goals: goals,
        profile: profile
    )

    static let dashboard = dashboard(for: .now, entries: entries, goals: goals, profile: profile, recommendations: recommendations)

    static func dashboard(
        for date: Date,
        entries: [DrinkLogEntry],
        goals: HealthGoalsSummary,
        profile: UserProfileSummary,
        recommendations: [RecommendationCard]? = nil
    ) -> DashboardState {
        let aggregate = entries.reduce(into: IngredientMetrics.zero) { partialResult, entry in
            partialResult = partialResult.adding(entry.metrics)
        }

        let grouped = Dictionary(grouping: entries, by: \.category)
        let breakdown = grouped
            .map { category, values in
                CategoryBreakdownSummary(
                    category: category,
                    entriesCount: values.count,
                    hydrationML: values.reduce(0) { $0 + $1.metrics.hydrationML }
                )
            }
            .sorted { lhs, rhs in
                lhs.hydrationML > rhs.hydrationML
            }

        return DashboardState(
            date: date,
            aggregate: aggregate,
            goals: goals,
            recommendations: recommendations ?? buildRecommendations(aggregate: aggregate, goals: goals, profile: profile),
            todayEntries: entries.sorted { $0.consumedAt > $1.consumedAt },
            categoryBreakdown: breakdown
        )
    }

    static func previewSearchResults(for query: String) -> [DrinkDefinitionSummary] {
        guard query.isEmpty == false else { return drinks }
        return drinks.filter { drink in
            drink.name.localizedCaseInsensitiveContains(query)
                || drink.category.localizedCaseInsensitiveContains(query)
                || drink.brand.localizedCaseInsensitiveContains(query)
        }
    }

    static func buildRecommendations(
        aggregate: IngredientMetrics,
        goals: HealthGoalsSummary,
        profile: UserProfileSummary
    ) -> [RecommendationCard] {
        var cards: [RecommendationCard] = []

        if aggregate.sugarG >= goals.sugarLimitG * 0.8 {
            let severity = aggregate.sugarG > goals.sugarLimitG ? "critical" : "warning"
            cards.append(
                RecommendationCard(
                    ruleID: "sugar-warning",
                    severity: severity,
                    title: aggregate.sugarG > goals.sugarLimitG ? "今日糖分已超目标" : "今日糖分接近上限",
                    summary: "下一杯建议切换到无糖茶饮或气泡水，尽量避免继续叠加液体糖。",
                    explanation: RecommendationExplanation(
                        ruleID: "sugar-warning",
                        trigger: "糖分摄入达到提醒阈值",
                        inputs: [
                            "sugar_g": "\(Int(aggregate.sugarG))",
                            "limit_g": "\(Int(goals.sugarLimitG))",
                        ],
                        thresholdComparison: "\(Int(aggregate.sugarG))g / \(Int(goals.sugarLimitG))g",
                        action: "改喝无糖或半糖替代饮品",
                        risk: "连续高糖饮品会增加代谢负担"
                    )
                )
            )
        }

        if aggregate.caffeineMG >= goals.caffeineLimitMG * 0.8 {
            let severity = aggregate.caffeineMG > goals.caffeineLimitMG ? "critical" : "warning"
            cards.append(
                RecommendationCard(
                    ruleID: "caffeine-warning",
                    severity: severity,
                    title: aggregate.caffeineMG > goals.caffeineLimitMG ? "咖啡因已超过目标" : "咖啡因接近上限",
                    summary: "后续更适合切到低因或无咖啡因饮品，把提神留给步行和补水。",
                    explanation: RecommendationExplanation(
                        ruleID: "caffeine-warning",
                        trigger: "咖啡因摄入达到提醒阈值",
                        inputs: [
                            "caffeine_mg": "\(Int(aggregate.caffeineMG))",
                            "limit_mg": "\(Int(goals.caffeineLimitMG))",
                        ],
                        thresholdComparison: "\(Int(aggregate.caffeineMG))mg / \(Int(goals.caffeineLimitMG))mg",
                        action: "后续优先低因、无糖茶或白水",
                        risk: "连续叠加咖啡因会提高心悸和睡眠干扰风险"
                    )
                )
            )
        }

        if aggregate.caffeineMG > 0 {
            cards.append(
                RecommendationCard(
                    ruleID: "late-caffeine",
                    severity: "info",
                    title: "晚间咖啡因窗口提醒",
                    summary: "如果你通常 \(profile.sleepHourText) 入睡，今天 15:00 后尽量不再摄入高咖啡因。",
                    explanation: RecommendationExplanation(
                        ruleID: "late-caffeine",
                        trigger: "今日存在咖啡因摄入",
                        inputs: [
                            "sleep_time": profile.sleepHourText,
                            "caffeine_mg": "\(Int(aggregate.caffeineMG))",
                        ],
                        thresholdComparison: "\(profile.sleepHourText) -> 15:00",
                        action: "后续优先选择气泡水或热茶",
                        risk: "过晚咖啡因会影响入睡和深睡眠质量"
                    )
                )
            )
        }

        if cards.isEmpty {
            cards.append(
                RecommendationCard(
                    ruleID: "hydration-encouragement",
                    severity: "info",
                    title: "今天的节奏还不错",
                    summary: "继续优先低糖补水类饮品，把总摄入控制在稳定区间。",
                    explanation: RecommendationExplanation(
                        ruleID: "hydration-encouragement",
                        trigger: "当前摄入仍在安全范围内",
                        inputs: [
                            "hydration_ml": "\(Int(aggregate.hydrationML))",
                            "goal_ml": "\(Int(goals.hydrationGoalML))",
                        ],
                        thresholdComparison: "\(Int(aggregate.hydrationML))ml / \(Int(goals.hydrationGoalML))ml",
                        action: "下午继续补一杯低糖饮品或白水",
                        risk: "若长时间只靠含糖饮品补水，后续仍可能触发糖分风险"
                    )
                )
            )
        }

        return cards
    }
}
