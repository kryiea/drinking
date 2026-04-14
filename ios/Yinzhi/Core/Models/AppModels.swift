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

    enum CodingKeys: String, CodingKey {
        case caffeineMG = "caffeine_mg"
        case sugarG = "sugar_g"
        case caloriesKcal = "calories_kcal"
        case hydrationML = "hydration_ml"
        case volumeML = "volume_ml"
    }
}

struct DrinkServingOption: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var volumeML: Int
    var multiplier: Double = 1.0

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case volumeML = "volume_ml"
        case multiplier
    }
}

enum BrewMethod: String, Codable, Hashable, Sendable, CaseIterable {
    case handBrew = "hand-brew"
    case espressoMachine = "espresso-machine"
    case milkTea = "milk-tea"
    case sparkling = "sparkling"
    case readyToDrink = "ready-to-drink"

    var label: String {
        switch self {
        case .handBrew:
            return "手冲"
        case .espressoMachine:
            return "咖啡机"
        case .milkTea:
            return "奶茶"
        case .sparkling:
            return "气泡饮"
        case .readyToDrink:
            return "即饮"
        }
    }

    var systemImage: String {
        switch self {
        case .handBrew:
            return "drop.circle"
        case .espressoMachine:
            return "cup.and.saucer.fill"
        case .milkTea:
            return "takeoutbag.and.cup.and.straw.fill"
        case .sparkling:
            return "sparkles"
        case .readyToDrink:
            return "refrigerator"
        }
    }
}

enum BrewStrength: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case light
    case balanced
    case bold

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light:
            return "轻盈"
        case .balanced:
            return "均衡"
        case .bold:
            return "浓郁"
        }
    }

    var factor: Double {
        switch self {
        case .light:
            return 0.92
        case .balanced:
            return 1.0
        case .bold:
            return 1.08
        }
    }
}

struct BrewRecipeSummary: Codable, Hashable, Sendable {
    var method: BrewMethod
    var title: String
    var ratioText: String
    var coffeeG: Double
    var waterML: Double
    var outputML: Double
    var milkML: Double
    var concentrateML: Double
    var brewSeconds: Int
    var temperatureC: Int
    var grindText: String?
    var tastingNote: String?

    func scaled(targetVolumeML: Int, strength: BrewStrength) -> BrewPreviewResult {
        let base = max(outputML, 1)
        let scale = Double(targetVolumeML) / base
        return BrewPreviewResult(
            targetVolumeML: targetVolumeML,
            coffeeG: coffeeG * scale * strength.factor,
            waterML: waterML * scale,
            milkML: milkML * scale,
            concentrateML: concentrateML * scale * strength.factor,
            ratioText: ratioText,
            title: title,
            tastingNote: tastingNote
        )
    }

    enum CodingKeys: String, CodingKey {
        case method
        case title
        case ratioText = "ratio_text"
        case coffeeG = "coffee_g"
        case waterML = "water_ml"
        case outputML = "output_ml"
        case milkML = "milk_ml"
        case concentrateML = "concentrate_ml"
        case brewSeconds = "brew_seconds"
        case temperatureC = "temperature_c"
        case grindText = "grind_text"
        case tastingNote = "tasting_note"
    }
}

struct BrewPreviewResult: Hashable, Sendable {
    var targetVolumeML: Int
    var coffeeG: Double
    var waterML: Double
    var milkML: Double
    var concentrateML: Double
    var ratioText: String
    var title: String
    var tastingNote: String?
}

struct DrinkDefinitionSummary: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var category: String
    var brand: String
    var brandCollection: String?
    var tags: [String]
    var heroFlavor: String?
    var preparationMethods: [BrewMethod]?
    var brewRecipe: BrewRecipeSummary?
    var metrics: IngredientMetrics
    var servingOptions: [DrinkServingOption]

    var preferredServing: DrinkServingOption {
        servingOptions.first ?? DrinkServingOption(id: "default", name: "标准份", volumeML: Int(metrics.volumeML))
    }

    var methodLabels: [String] {
        (preparationMethods ?? []).map(\.label)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case brand
        case brandCollection = "brand_collection"
        case tags
        case heroFlavor = "hero_flavor"
        case preparationMethods = "preparation_methods"
        case brewRecipe = "brew_recipe"
        case metrics
        case servingOptions = "serving_options"
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
    var brand: String?
    var preparationMethod: BrewMethod?
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
        brand: String? = nil,
        preparationMethod: BrewMethod? = nil,
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
        self.brand = brand
        self.preparationMethod = preparationMethod
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

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case drinkDefinitionID = "drink_definition_id"
        case drinkName = "drink_name"
        case category
        case brand
        case preparationMethod = "preparation_method"
        case consumedAt = "consumed_at"
        case servingLabel = "serving_label"
        case metrics
        case note
        case source
        case version
        case syncStatus = "sync_status"
    }
}

struct RecommendationExplanation: Codable, Hashable, Sendable {
    var ruleID: String
    var trigger: String
    var inputs: [String: String]
    var thresholdComparison: String
    var action: String
    var risk: String

    enum CodingKeys: String, CodingKey {
        case ruleID = "rule_id"
        case trigger
        case inputs
        case thresholdComparison = "threshold_comparison"
        case action
        case risk
    }
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

    enum CodingKeys: String, CodingKey {
        case caffeineLimitMG = "caffeine_limit_mg"
        case sugarLimitG = "sugar_limit_g"
        case caloriesLimitKcal = "calories_limit_kcal"
        case hydrationGoalML = "hydration_goal_ml"
    }
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

    enum CodingKeys: String, CodingKey {
        case category
        case entriesCount = "entries_count"
        case hydrationML = "hydration_ml"
    }
}

struct DailyAggregateSnapshot: Codable, Hashable, Sendable {
    var date: Date
    var totals: IngredientMetrics
    var entriesCount: Int
    var categoryBreakdown: [CategoryBreakdownSummary]

    enum CodingKeys: String, CodingKey {
        case date
        case totals
        case entriesCount = "entries_count"
        case categoryBreakdown = "category_breakdown"
    }
}

struct SyncEnvelopeSummary: Codable, Hashable, Sendable {
    var lastSyncedAt: Date?
    var pendingEntryIDs: [String]
    var conflictCount: Int

    var pendingCount: Int {
        pendingEntryIDs.count
    }

    enum CodingKeys: String, CodingKey {
        case lastSyncedAt = "last_synced_at"
        case pendingEntryIDs = "pending_entry_ids"
        case conflictCount = "conflict_count"
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

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case userID = "user_id"
        case displayName = "display_name"
        case sync
        case issuedAt
    }
}

struct CreateDrinkLogInput: Codable, Hashable, Sendable {
    var drinkDefinitionID: String
    var servingOptionID: String?
    var ratio: Double
    var consumedAt: Date
    var note: String?
    var source: DrinkLogSource

    enum CodingKeys: String, CodingKey {
        case drinkDefinitionID = "drink_definition_id"
        case servingOptionID = "serving_option_id"
        case ratio
        case consumedAt = "consumed_at"
        case note
        case source
    }
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
            brand: "MANNER",
            brandCollection: "城市咖啡",
            tags: ["办公", "早餐", "意式机"],
            heroFlavor: "燕麦坚果",
            preparationMethods: [.espressoMachine, .readyToDrink],
            brewRecipe: BrewRecipeSummary(
                method: .espressoMachine,
                title: "双份意式燕麦拿铁",
                ratioText: "18g 粉 -> 36g 浓缩",
                coffeeG: 18,
                waterML: 0,
                outputML: 320,
                milkML: 230,
                concentrateML: 36,
                brewSeconds: 30,
                temperatureC: 93,
                grindText: "意式细研磨",
                tastingNote: "顺滑、坚果、适合通勤"
            ),
            metrics: IngredientMetrics(caffeineMG: 120, sugarG: 7, caloriesKcal: 145, hydrationML: 260, volumeML: 320),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 320, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "jasmine-milk-tea",
            name: "茉莉奶绿",
            category: "奶茶",
            brand: "霸王茶姬",
            brandCollection: "东方茶饮",
            tags: ["下午茶", "高糖", "品牌款"],
            heroFlavor: "茉莉鲜奶",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 55, sugarG: 28, caloriesKcal: 265, hydrationML: 480, volumeML: 500),
            servingOptions: [.init(id: "half-sugar", name: "半糖", volumeML: 500, multiplier: 0.78)]
        ),
        DrinkDefinitionSummary(
            id: "sparkling-water",
            name: "青柠气泡水",
            category: "气泡饮",
            brand: "元气森林",
            brandCollection: "轻负担补水",
            tags: ["低糖", "补水", "即饮"],
            heroFlavor: "青柠清爽",
            preparationMethods: [.sparkling, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 0, sugarG: 1, caloriesKcal: 12, hydrationML: 330, volumeML: 330),
            servingOptions: [.init(id: "can", name: "一听", volumeML: 330, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "energy-shot",
            name: "能量饮料",
            category: "功能饮料",
            brand: "东鹏特饮",
            brandCollection: "高刺激补能",
            tags: ["加班", "高咖啡因", "即饮"],
            heroFlavor: "高刺激提神",
            preparationMethods: [.readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 180, sugarG: 24, caloriesKcal: 165, hydrationML: 250, volumeML: 250),
            servingOptions: [.init(id: "bottle", name: "标准瓶", volumeML: 250, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "pour-over-yirgacheffe",
            name: "耶加雪菲手冲",
            category: "手冲咖啡",
            brand: "Blue Bottle",
            brandCollection: "精品咖啡",
            tags: ["手冲", "果酸", "单品"],
            heroFlavor: "花香柑橘",
            preparationMethods: [.handBrew],
            brewRecipe: BrewRecipeSummary(
                method: .handBrew,
                title: "V60 手冲参考",
                ratioText: "1:16",
                coffeeG: 18,
                waterML: 300,
                outputML: 260,
                milkML: 0,
                concentrateML: 0,
                brewSeconds: 195,
                temperatureC: 92,
                grindText: "中细研磨",
                tastingNote: "花香、柑橘、酸质明亮"
            ),
            metrics: IngredientMetrics(caffeineMG: 130, sugarG: 0, caloriesKcal: 6, hydrationML: 255, volumeML: 260),
            servingOptions: [.init(id: "v60", name: "V60 一杯份", volumeML: 260, multiplier: 1.0)]
        ),
    ]

    static let entries: [DrinkLogEntry] = [
        DrinkLogEntry(
            id: "entry-1",
            userID: "preview-user",
            drinkDefinitionID: "latte-oat",
            drinkName: "燕麦拿铁",
            category: "咖啡",
            brand: "MANNER",
            preparationMethod: .espressoMachine,
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
            brand: "霸王茶姬",
            preparationMethod: .milkTea,
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
