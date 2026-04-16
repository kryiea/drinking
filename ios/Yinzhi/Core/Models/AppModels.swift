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

enum CalculatorBrewMethod: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case espresso
    case pourOver
    case capsule

    var id: String { rawValue }

    var title: String {
        switch self {
        case .espresso:
            return "意式浓缩"
        case .pourOver:
            return "手冲"
        case .capsule:
            return "胶囊"
        }
    }

    var accentHexName: String {
        switch self {
        case .espresso:
            return "espresso"
        case .pourOver:
            return "pour-over"
        case .capsule:
            return "capsule"
        }
    }

    var defaultBeansGrams: Double {
        switch self {
        case .espresso:
            return 18
        case .pourOver:
            return 18
        case .capsule:
            return 6
        }
    }

    var defaultWaterML: Double {
        switch self {
        case .espresso:
            return 36
        case .pourOver:
            return 300
        case .capsule:
            return 40
        }
    }

    var defaultRoast: RoastLevel {
        switch self {
        case .espresso:
            return .medium
        case .pourOver:
            return .light
        case .capsule:
            return .medium
        }
    }

    var defaultGrind: GrindLevel {
        switch self {
        case .espresso:
            return .fine
        case .pourOver:
            return .medium
        case .capsule:
            return .standard
        }
    }

    var extractionFactor: Double {
        switch self {
        case .espresso:
            return 0.92
        case .pourOver:
            return 1.08
        case .capsule:
            return 0.82
        }
    }

    var parameterLine: String {
        switch self {
        case .espresso:
            return "9bar · 92°C"
        case .pourOver:
            return "92°C · 1:16"
        case .capsule:
            return "19bar · 88°C"
        }
    }
}

enum RoastLevel: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case light
    case medium
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light:
            return "浅度"
        case .medium:
            return "中度"
        case .dark:
            return "深度"
        }
    }

    var factor: Double {
        switch self {
        case .light:
            return 1.04
        case .medium:
            return 1.0
        case .dark:
            return 0.93
        }
    }
}

enum GrindLevel: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case fine
    case standard
    case medium
    case coarse

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fine:
            return "细"
        case .standard:
            return "标准"
        case .medium:
            return "中"
        case .coarse:
            return "粗"
        }
    }

    var factor: Double {
        switch self {
        case .fine:
            return 1.05
        case .standard:
            return 1.0
        case .medium:
            return 0.98
        case .coarse:
            return 0.93
        }
    }
}

struct CaffeineCalculatorInput: Hashable, Sendable {
    var method: CalculatorBrewMethod
    var beansGrams: Double
    var waterML: Double
    var roastLevel: RoastLevel
    var grindLevel: GrindLevel

    static func preset(for method: CalculatorBrewMethod) -> CaffeineCalculatorInput {
        CaffeineCalculatorInput(
            method: method,
            beansGrams: method.defaultBeansGrams,
            waterML: method.defaultWaterML,
            roastLevel: method.defaultRoast,
            grindLevel: method.defaultGrind
        )
    }
}

enum CaffeineCalculatorEstimator {
    static func estimateMG(for input: CaffeineCalculatorInput) -> Int {
        let basePerGram = 10.8
        let waterRatio = max(input.waterML / max(input.method.defaultWaterML, 1), 0.55)
        let waterFactor = min(max(pow(waterRatio, 0.18), 0.86), 1.16)
        let estimate =
            input.beansGrams
            * basePerGram
            * input.method.extractionFactor
            * input.roastLevel.factor
            * input.grindLevel.factor
            * waterFactor

        return Int(estimate.rounded())
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

enum CaffeineMetabolismProfile: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case quick
    case standard
    case sensitive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .quick:
            return "代谢偏快"
        case .standard:
            return "标准"
        case .sensitive:
            return "更敏感"
        }
    }

    var caption: String {
        switch self {
        case .quick:
            return "半衰期约 4.5h"
        case .standard:
            return "半衰期约 5.5h"
        case .sensitive:
            return "半衰期约 7h"
        }
    }

    var halfLifeHours: Double {
        switch self {
        case .quick:
            return 4.5
        case .standard:
            return 5.5
        case .sensitive:
            return 7.0
        }
    }

    var safeSleepThresholdMG: Double {
        switch self {
        case .quick:
            return 40
        case .standard:
            return 35
        case .sensitive:
            return 22
        }
    }
}

struct UserPreferenceSnapshot: Codable, Hashable, Sendable {
    var sleepHour: Int
    var sleepMinute: Int
    var metabolismProfile: CaffeineMetabolismProfile
    var iCloudPlanEnabled: Bool
    var watchPlanEnabled: Bool

    static let `default` = UserPreferenceSnapshot(
        sleepHour: 23,
        sleepMinute: 30,
        metabolismProfile: .standard,
        iCloudPlanEnabled: true,
        watchPlanEnabled: true
    )

    var sleepHourText: String {
        String(format: "%02d:%02d", sleepHour, sleepMinute)
    }

    var halfLifeHours: Double {
        metabolismProfile.halfLifeHours
    }

    var safeSleepThresholdMG: Double {
        metabolismProfile.safeSleepThresholdMG
    }

    func withSleepDate(_ date: Date, calendar: Calendar = .current) -> UserPreferenceSnapshot {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return UserPreferenceSnapshot(
            sleepHour: components.hour ?? sleepHour,
            sleepMinute: components.minute ?? sleepMinute,
            metabolismProfile: metabolismProfile,
            iCloudPlanEnabled: iCloudPlanEnabled,
            watchPlanEnabled: watchPlanEnabled
        )
    }

    var sleepDateToday: Date {
        nextSleepDate(from: .now)
    }

    func nextSleepDate(from reference: Date, calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: reference)
        components.hour = sleepHour
        components.minute = sleepMinute
        components.second = 0

        let sameDay = calendar.date(from: components) ?? reference
        if sameDay > reference {
            return sameDay
        }
        return calendar.date(byAdding: .day, value: 1, to: sameDay) ?? sameDay.addingTimeInterval(24 * 3600)
    }
}

struct UserDrinkTemplate: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var brand: String
    var name: String
    var category: String
    var caffeineMG: Double
    var sugarG: Double
    var volumeML: Int
    var preparationMethod: BrewMethod?

    var detailLine: String {
        let method = preparationMethod?.label ?? "未设方式"
        return "\(category) · \(method) · \(Int(caffeineMG))mg · \(volumeML)ml"
    }

    var asDrinkDefinition: DrinkDefinitionSummary {
        DrinkDefinitionSummary(
            id: id,
            name: name,
            category: category,
            brand: brand,
            brandCollection: "我添加的饮品",
            tags: ["自定义", category],
            heroFlavor: "自定义饮品",
            preparationMethods: preparationMethod.map { [$0] },
            metrics: IngredientMetrics(
                caffeineMG: caffeineMG,
                sugarG: sugarG,
                caloriesKcal: 0,
                hydrationML: Double(volumeML),
                volumeML: Double(volumeML)
            ),
            servingOptions: [
                DrinkServingOption(id: "default", name: "标准杯", volumeML: volumeML, multiplier: 1.0),
            ]
        )
    }
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

enum SleepReadinessState: String, Codable, Hashable, Sendable {
    case sleepFriendly = "sleep-friendly"
    case watch
    case likelyDisruptive = "likely-disruptive"

    var label: String {
        switch self {
        case .sleepFriendly:
            return "适合入睡"
        case .watch:
            return "仍需观察"
        case .likelyDisruptive:
            return "可能扰睡"
        }
    }

    var systemImage: String {
        switch self {
        case .sleepFriendly:
            return "bed.double.fill"
        case .watch:
            return "moon.zzz"
        case .likelyDisruptive:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct CaffeineForecastPointSummary: Identifiable, Codable, Hashable, Sendable {
    var id: Date { at }
    var at: Date
    var remainingCaffeineMG: Double
    var stage: SleepReadinessState

    enum CodingKeys: String, CodingKey {
        case at
        case remainingCaffeineMG = "remaining_caffeine_mg"
        case stage
    }
}

struct CaffeineForecastSummary: Codable, Hashable, Sendable {
    var calculatedAt: Date
    var sleepAt: Date
    var halfLifeHours: Double
    var currentEstimateMG: Double
    var projectedSleepMG: Double
    var safeSleepThresholdMG: Double
    var recommendedSleepTime: Date?
    var sleepReadiness: SleepReadinessState
    var summary: String
    var sleepImpact: String
    var timeline: [CaffeineForecastPointSummary]

    enum CodingKeys: String, CodingKey {
        case calculatedAt = "calculated_at"
        case sleepAt = "sleep_at"
        case halfLifeHours = "half_life_hours"
        case currentEstimateMG = "current_estimate_mg"
        case projectedSleepMG = "projected_sleep_mg"
        case safeSleepThresholdMG = "safe_sleep_threshold_mg"
        case recommendedSleepTime = "recommended_sleep_time"
        case sleepReadiness = "sleep_readiness"
        case summary
        case sleepImpact = "sleep_impact"
        case timeline
    }
}

struct DailyAIBriefSummary: Codable, Hashable, Sendable {
    var mode: String
    var generatedAt: Date
    var headline: String
    var narrative: String
    var nextActions: [String]
    var sleepNote: String

    var isLive: Bool {
        mode == "live"
    }

    enum CodingKeys: String, CodingKey {
        case mode
        case generatedAt = "generated_at"
        case headline
        case narrative
        case nextActions = "next_actions"
        case sleepNote = "sleep_note"
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
    var caffeineForecast: CaffeineForecastSummary
    var aiBrief: DailyAIBriefSummary
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

    static let userPreferences = UserPreferenceSnapshot.default

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
        DrinkDefinitionSummary(
            id: "americano-iced",
            name: "冰美式",
            category: "咖啡",
            brand: "瑞幸",
            brandCollection: "日常通勤",
            tags: ["低糖", "即点", "意式机"],
            heroFlavor: "清爽黑咖",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 140, sugarG: 0, caloriesKcal: 8, hydrationML: 360, volumeML: 380),
            servingOptions: [.init(id: "large", name: "大杯", volumeML: 380, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "luckin-coconut-latte",
            name: "生椰拿铁",
            category: "咖啡",
            brand: "瑞幸",
            brandCollection: "日常通勤",
            tags: ["椰乳", "奶咖", "高频"],
            heroFlavor: "生椰奶香",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 126, sugarG: 10, caloriesKcal: 168, hydrationML: 285, volumeML: 320),
            servingOptions: [.init(id: "regular", name: "中杯", volumeML: 320, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "luckin-velvet-latte",
            name: "丝绒拿铁",
            category: "咖啡",
            brand: "瑞幸",
            brandCollection: "日常通勤",
            tags: ["奶咖", "顺滑", "高频"],
            heroFlavor: "奶香可可",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 132, sugarG: 11, caloriesKcal: 182, hydrationML: 290, volumeML: 340),
            servingOptions: [.init(id: "large", name: "大杯", volumeML: 340, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "starbucks-flat-white",
            name: "馥芮白",
            category: "咖啡",
            brand: "星巴克",
            brandCollection: "经典意式",
            tags: ["奶咖", "意式机", "高频"],
            heroFlavor: "浓缩奶香",
            preparationMethods: [.espressoMachine],
            metrics: IngredientMetrics(caffeineMG: 130, sugarG: 9, caloriesKcal: 150, hydrationML: 250, volumeML: 330),
            servingOptions: [.init(id: "tall", name: "中杯", volumeML: 330, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "starbucks-americano",
            name: "美式咖啡",
            category: "咖啡",
            brand: "星巴克",
            brandCollection: "经典意式",
            tags: ["黑咖", "意式机", "高频"],
            heroFlavor: "坚果焦糖",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 150, sugarG: 0, caloriesKcal: 10, hydrationML: 340, volumeML: 355),
            servingOptions: [.init(id: "tall", name: "中杯", volumeML: 355, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "starbucks-shaken-oat-latte",
            name: "冰摇浓缩燕麦拿铁",
            category: "咖啡",
            brand: "星巴克",
            brandCollection: "经典意式",
            tags: ["燕麦", "冰咖", "奶咖"],
            heroFlavor: "燕麦焦糖",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 145, sugarG: 9, caloriesKcal: 148, hydrationML: 285, volumeML: 350),
            servingOptions: [.init(id: "grande", name: "大杯", volumeML: 350, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "cotti-coconut-latte",
            name: "生椰米乳拿铁",
            category: "咖啡",
            brand: "库迪",
            brandCollection: "日常通勤",
            tags: ["奶咖", "通勤", "椰香"],
            heroFlavor: "椰乳谷物",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 118, sugarG: 11, caloriesKcal: 182, hydrationML: 285, volumeML: 360),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 360, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "cotti-orange-americano",
            name: "橙C美式",
            category: "咖啡",
            brand: "库迪",
            brandCollection: "日常通勤",
            tags: ["果咖", "美式", "高频"],
            heroFlavor: "橙香黑咖",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 136, sugarG: 6, caloriesKcal: 84, hydrationML: 320, volumeML: 420),
            servingOptions: [.init(id: "large", name: "大杯", volumeML: 420, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "cotti-latte",
            name: "拿铁",
            category: "咖啡",
            brand: "库迪",
            brandCollection: "日常通勤",
            tags: ["奶咖", "通勤", "基础款"],
            heroFlavor: "牛奶坚果",
            preparationMethods: [.espressoMachine, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 122, sugarG: 8, caloriesKcal: 146, hydrationML: 270, volumeML: 320),
            servingOptions: [.init(id: "regular", name: "中杯", volumeML: 320, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "bo-ya-jue-xian",
            name: "伯牙绝弦",
            category: "奶茶",
            brand: "霸王茶姬",
            brandCollection: "招牌奶茶",
            tags: ["乌龙", "奶茶", "品牌款"],
            heroFlavor: "茶香奶韵",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 82, sugarG: 22, caloriesKcal: 240, hydrationML: 430, volumeML: 500),
            servingOptions: [.init(id: "less-sugar", name: "少糖", volumeML: 500, multiplier: 0.9)]
        ),
        DrinkDefinitionSummary(
            id: "chagee-flower-oolong",
            name: "花田乌龙",
            category: "奶茶",
            brand: "霸王茶姬",
            brandCollection: "东方茶饮",
            tags: ["乌龙", "轻乳", "高频"],
            heroFlavor: "花香乌龙",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 66, sugarG: 20, caloriesKcal: 198, hydrationML: 438, volumeML: 500),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 500, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "chagee-white-mist",
            name: "白雾红尘",
            category: "奶茶",
            brand: "霸王茶姬",
            brandCollection: "东方茶饮",
            tags: ["红茶", "奶茶", "丝滑"],
            heroFlavor: "红茶奶香",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 60, sugarG: 23, caloriesKcal: 212, hydrationML: 430, volumeML: 500),
            servingOptions: [.init(id: "less-sugar", name: "少糖", volumeML: 500, multiplier: 0.88)]
        ),
        DrinkDefinitionSummary(
            id: "grape-jasmine",
            name: "多肉葡萄",
            category: "果茶",
            brand: "喜茶",
            brandCollection: "果茶",
            tags: ["果茶", "高频", "品牌款"],
            heroFlavor: "葡萄茉莉",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 28, sugarG: 26, caloriesKcal: 210, hydrationML: 420, volumeML: 500),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 500, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "heytea-cheese-grape",
            name: "轻芝多肉葡萄",
            category: "果茶",
            brand: "喜茶",
            brandCollection: "果茶",
            tags: ["芝士", "葡萄", "高频"],
            heroFlavor: "葡萄芝香",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 30, sugarG: 24, caloriesKcal: 228, hydrationML: 415, volumeML: 500),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 500, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "heytea-black-sugar-bobo",
            name: "烤黑糖波波牛乳",
            category: "奶茶",
            brand: "喜茶",
            brandCollection: "经典奶茶",
            tags: ["黑糖", "波波", "牛乳"],
            heroFlavor: "黑糖焦香",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 36, sugarG: 31, caloriesKcal: 286, hydrationML: 388, volumeML: 500),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 500, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "alittle-boba-milk-tea",
            name: "波霸奶茶",
            category: "奶茶",
            brand: "一点点",
            brandCollection: "经典奶茶",
            tags: ["珍珠", "奶茶", "高频"],
            heroFlavor: "红茶奶香",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 54, sugarG: 32, caloriesKcal: 298, hydrationML: 400, volumeML: 500),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 500, multiplier: 1.0)]
        ),
        DrinkDefinitionSummary(
            id: "alittle-four-season-macchiato",
            name: "四季春玛奇朵",
            category: "奶茶",
            brand: "一点点",
            brandCollection: "清爽茶乳",
            tags: ["四季春", "奶盖", "高频"],
            heroFlavor: "奶盖青茶",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 46, sugarG: 20, caloriesKcal: 176, hydrationML: 430, volumeML: 500),
            servingOptions: [.init(id: "less-sugar", name: "少糖", volumeML: 500, multiplier: 0.88)]
        ),
        DrinkDefinitionSummary(
            id: "alittle-oolong-milk-tea",
            name: "乌龙奶茶",
            category: "奶茶",
            brand: "一点点",
            brandCollection: "经典奶茶",
            tags: ["乌龙", "奶茶", "经典"],
            heroFlavor: "焙香乌龙",
            preparationMethods: [.milkTea, .readyToDrink],
            metrics: IngredientMetrics(caffeineMG: 58, sugarG: 26, caloriesKcal: 232, hydrationML: 418, volumeML: 500),
            servingOptions: [.init(id: "regular", name: "标准杯", volumeML: 500, multiplier: 1.0)]
        ),
    ]

    static let userDrinkTemplates: [UserDrinkTemplate] = [
        UserDrinkTemplate(
            id: "user-cold-brew-home",
            brand: "我的常喝",
            name: "家里冷萃",
            category: "咖啡",
            caffeineMG: 110,
            sugarG: 0,
            volumeML: 280,
            preparationMethod: .readyToDrink
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

    static let caffeineForecast = buildCaffeineForecast(entries: entries, profile: profile, preferences: userPreferences)

    static let aiBrief = buildAIBrief(
        aggregate: entries.reduce(into: .zero) { partialResult, entry in
            partialResult = partialResult.adding(entry.metrics)
        },
        goals: goals,
        profile: profile,
        forecast: caffeineForecast,
        recommendations: recommendations
    )

    static let dashboard = dashboard(
        for: .now,
        entries: entries,
        goals: goals,
        profile: profile,
        preferences: userPreferences,
        recommendations: recommendations,
        caffeineForecast: caffeineForecast,
        aiBrief: aiBrief
    )

    static func dashboard(
        for date: Date,
        entries: [DrinkLogEntry],
        goals: HealthGoalsSummary,
        profile: UserProfileSummary,
        preferences: UserPreferenceSnapshot = userPreferences,
        recommendations: [RecommendationCard]? = nil,
        caffeineForecast: CaffeineForecastSummary? = nil,
        aiBrief: DailyAIBriefSummary? = nil
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
            categoryBreakdown: breakdown,
            caffeineForecast: caffeineForecast ?? buildCaffeineForecast(entries: entries, profile: profile, preferences: preferences),
            aiBrief: aiBrief ?? buildAIBrief(
                aggregate: aggregate,
                goals: goals,
                profile: profile,
                forecast: caffeineForecast ?? buildCaffeineForecast(entries: entries, profile: profile, preferences: preferences),
                recommendations: recommendations ?? buildRecommendations(aggregate: aggregate, goals: goals, profile: profile)
            )
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

    static func buildCaffeineForecast(
        entries: [DrinkLogEntry],
        profile: UserProfileSummary,
        preferences: UserPreferenceSnapshot = userPreferences,
        now: Date = .now
    ) -> CaffeineForecastSummary {
        let halfLife = preferences.halfLifeHours
        let safeThreshold = preferences.safeSleepThresholdMG
        let sleepAt = preferences.nextSleepDate(from: now)
        let currentEstimate = remainingCaffeine(entries: entries, at: now, halfLifeHours: halfLife)
        let projectedSleep = remainingCaffeine(entries: entries, at: sleepAt, halfLifeHours: halfLife)
        let readiness = sleepStage(for: projectedSleep, safeThreshold: safeThreshold)
        let recommendedSleepTime = recommendedSleepDate(
            entries: entries,
            start: now,
            halfLifeHours: halfLife,
            safeThreshold: safeThreshold
        )

        let timelineEnd = min(max(sleepAt, now.addingTimeInterval(4 * 3600)).addingTimeInterval(4 * 3600), now.addingTimeInterval(12 * 3600))
        var timeline: [CaffeineForecastPointSummary] = []
        var cursor = now
        while cursor <= timelineEnd {
            let remaining = remainingCaffeine(entries: entries, at: cursor, halfLifeHours: halfLife)
            timeline.append(
                CaffeineForecastPointSummary(
                    at: cursor,
                    remainingCaffeineMG: remaining,
                    stage: sleepStage(for: remaining, safeThreshold: safeThreshold)
                )
            )
            cursor = cursor.addingTimeInterval(3600)
        }

        return CaffeineForecastSummary(
            calculatedAt: now,
            sleepAt: sleepAt,
            halfLifeHours: halfLife,
            currentEstimateMG: currentEstimate,
            projectedSleepMG: projectedSleep,
            safeSleepThresholdMG: safeThreshold,
            recommendedSleepTime: recommendedSleepTime,
            sleepReadiness: readiness,
            summary: buildForecastSummary(
                sleepAt: sleepAt,
                projectedSleepMG: projectedSleep,
                readiness: readiness,
                recommendedSleepTime: recommendedSleepTime
            ),
            sleepImpact: buildSleepImpact(
                readiness: readiness,
                safeThreshold: safeThreshold,
                projectedSleepMG: projectedSleep
            ),
            timeline: timeline
        )
    }

    static func buildAIBrief(
        aggregate: IngredientMetrics,
        goals: HealthGoalsSummary,
        profile: UserProfileSummary,
        forecast: CaffeineForecastSummary,
        recommendations: [RecommendationCard],
        mode: String = "fallback"
    ) -> DailyAIBriefSummary {
        let actions = aiActions(aggregate: aggregate, goals: goals, forecast: forecast)
        return DailyAIBriefSummary(
            mode: mode,
            generatedAt: .now,
            headline: recommendations.first?.title ?? "今天的饮品节奏相对平稳",
            narrative: "今天累计咖啡因 \(Int(aggregate.caffeineMG))mg、糖分 \(Int(aggregate.sugarG))g。按 \(profile.sleepHourText) 入睡估算，\(forecast.summary)",
            nextActions: actions,
            sleepNote: forecast.sleepImpact
        )
    }

    private static func aiActions(
        aggregate: IngredientMetrics,
        goals: HealthGoalsSummary,
        forecast: CaffeineForecastSummary
    ) -> [String] {
        var actions: [String] = []
        if forecast.sleepReadiness != .sleepFriendly {
            actions.append("今晚后续优先无咖啡因饮品，把提神换成走动或补水。")
        }
        if aggregate.sugarG >= goals.sugarLimitG * 0.8 {
            actions.append("下一杯优先无糖或半糖版本，先把液体糖停下来。")
        }
        if aggregate.hydrationML < goals.hydrationGoalML * 0.75 {
            actions.append("补一杯白水或无糖茶，把补水目标往前追回来。")
        }
        if actions.isEmpty {
            actions.append("继续保持当前节奏，观察后半天的变化。")
        }
        return Array(actions.prefix(3))
    }

    private static func nextSleepDate(from now: Date, sleepText: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        let timeDate = formatter.date(from: sleepText) ?? now
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: timeDate)
        let todaySleep = calendar.date(
            bySettingHour: components.hour ?? 23,
            minute: components.minute ?? 30,
            second: 0,
            of: now
        ) ?? now
        if todaySleep > now {
            return todaySleep
        }
        return calendar.date(byAdding: .day, value: 1, to: todaySleep) ?? todaySleep
    }

    private static func remainingCaffeine(entries: [DrinkLogEntry], at date: Date, halfLifeHours: Double) -> Double {
        let rate = log(2) / halfLifeHours
        let total = entries.reduce(0.0) { partialResult, entry in
            guard entry.metrics.caffeineMG > 0, entry.consumedAt <= date else {
                return partialResult
            }
            let elapsed = max(date.timeIntervalSince(entry.consumedAt) / 3600, 0)
            return partialResult + entry.metrics.caffeineMG * Foundation.exp(-rate * elapsed)
        }
        return total.rounded(toPlaces: 1)
    }

    private static func sleepStage(for remaining: Double, safeThreshold: Double) -> SleepReadinessState {
        if remaining <= safeThreshold {
            return .sleepFriendly
        }
        if remaining <= safeThreshold * 2 {
            return .watch
        }
        return .likelyDisruptive
    }

    private static func recommendedSleepDate(
        entries: [DrinkLogEntry],
        start: Date,
        halfLifeHours: Double,
        safeThreshold: Double
    ) -> Date? {
        if remainingCaffeine(entries: entries, at: start, halfLifeHours: halfLifeHours) <= safeThreshold {
            return start
        }
        for step in 1 ... 72 {
            let candidate = start.addingTimeInterval(Double(step) * 1800)
            if remainingCaffeine(entries: entries, at: candidate, halfLifeHours: halfLifeHours) <= safeThreshold {
                return candidate
            }
        }
        return nil
    }

    private static func buildForecastSummary(
        sleepAt: Date,
        projectedSleepMG: Double,
        readiness: SleepReadinessState,
        recommendedSleepTime: Date?
    ) -> String {
        let sleepText = sleepAt.formatted(date: .omitted, time: .shortened)
        if readiness == .sleepFriendly {
            return "按 \(sleepText) 入睡计算，届时预计剩余 \(Int(projectedSleepMG))mg 咖啡因，影响相对可控。"
        }
        if let recommendedSleepTime {
            return "按 \(sleepText) 入睡计算，届时预计仍有 \(Int(projectedSleepMG))mg 残留，更接近适合入睡的时间大约在 \(recommendedSleepTime.formatted(date: .omitted, time: .shortened))。"
        }
        return "按 \(sleepText) 入睡计算，届时预计仍有 \(Int(projectedSleepMG))mg 残留，今晚更可能拖慢入睡。"
    }

    private static func buildSleepImpact(
        readiness: SleepReadinessState,
        safeThreshold: Double,
        projectedSleepMG: Double
    ) -> String {
        switch readiness {
        case .sleepFriendly:
            return "睡前残留约 \(Int(projectedSleepMG))mg，低于参考阈值 \(Int(safeThreshold))mg。"
        case .watch:
            return "睡前残留约 \(Int(projectedSleepMG))mg，仍高于参考阈值，可能让你更浅眠。"
        case .likelyDisruptive:
            return "睡前残留约 \(Int(projectedSleepMG))mg，明显高于参考阈值，更容易拖慢入睡。"
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
