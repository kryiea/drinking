import XCTest
@testable import Yinzhi

final class SmokeTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }

    func testAPIDecoderSupportsNaiveDateTimeValues() throws {
        let payload = """
        {
          "access_token": "demo-session-debug-token",
          "token_type": "bearer",
          "expires_in": 3600,
          "user_id": "apple-ug-token",
          "display_name": "饮知用户",
          "sync": {
            "last_synced_at": "2026-04-14T16:01:42.053554",
            "pending_entry_ids": [],
            "conflict_count": 0
          }
        }
        """.data(using: .utf8)!

        let decoder = APICodingFactory.makeDecoder()
        let session = try decoder.decode(SessionPayloadProbe.self, from: payload)

        XCTAssertEqual(session.userID, "apple-ug-token")
        XCTAssertNotNil(session.sync.lastSyncedAt)
    }

    func testAPIDecoderSupportsDrinkCatalogPayload() throws {
        let payload = """
        [
          {
            "id": "latte-oat",
            "name": "燕麦拿铁",
            "category": "咖啡",
            "brand": "MANNER",
            "brand_collection": "城市咖啡",
            "tags": ["早餐", "办公"],
            "hero_flavor": "燕麦坚果",
            "preparation_methods": ["espresso-machine", "ready-to-drink"],
            "brew_recipe": {
              "method": "espresso-machine",
              "title": "双份意式燕麦拿铁",
              "ratio_text": "18g 粉 -> 36g 浓缩",
              "coffee_g": 18.0,
              "water_ml": 0.0,
              "output_ml": 320.0,
              "milk_ml": 230.0,
              "concentrate_ml": 36.0,
              "brew_seconds": 30,
              "temperature_c": 93,
              "grind_text": "意式细研磨",
              "tasting_note": "适合晨间通勤的坚果甜感"
            },
            "metrics": {
              "caffeine_mg": 120.0,
              "sugar_g": 7.0,
              "calories_kcal": 145.0,
              "hydration_ml": 260.0,
              "volume_ml": 320.0
            },
            "serving_options": [
              {
                "id": "regular",
                "name": "标准杯",
                "volume_ml": 320,
                "multiplier": 1.0
              }
            ],
            "template_source": "seed"
          }
        ]
        """.data(using: .utf8)!

        let decoder = APICodingFactory.makeDecoder()
        let catalog = try decoder.decode([DrinkDefinitionSummary].self, from: payload)

        XCTAssertEqual(catalog.first?.metrics.caffeineMG, 120)
        XCTAssertEqual(catalog.first?.preparationMethods?.first, .espressoMachine)
    }

    func testAPIDecoderSupportsDailyAggregatePayload() throws {
        let payload = """
        {
          "date": "2026-04-15",
          "totals": {
            "caffeine_mg": 120.0,
            "sugar_g": 7.0,
            "calories_kcal": 145.0,
            "hydration_ml": 260.0,
            "volume_ml": 320.0
          },
          "entries_count": 1,
          "category_breakdown": [
            {
              "category": "咖啡",
              "entries_count": 1,
              "hydration_ml": 260.0
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = APICodingFactory.makeDecoder()
        let aggregate = try decoder.decode(DailyAggregateSnapshot.self, from: payload)

        XCTAssertEqual(aggregate.entriesCount, 1)
        XCTAssertEqual(aggregate.categoryBreakdown.first?.category, "咖啡")
    }

    func testAPIDecoderSupportsCaffeineForecastAndAIBrief() throws {
        let forecastPayload = """
        {
          "calculated_at": "2026-04-15T20:10:00",
          "sleep_at": "2026-04-15T23:30:00",
          "half_life_hours": 5.0,
          "current_estimate_mg": 118.4,
          "projected_sleep_mg": 74.0,
          "safe_sleep_threshold_mg": 35.0,
          "recommended_sleep_time": "2026-04-16T01:30:00",
          "sleep_readiness": "likely-disruptive",
          "summary": "按 23:30 入睡计算，届时预计仍有 74mg 咖啡因残留。",
          "sleep_impact": "睡前残留约 74mg，明显高于参考阈值。",
          "timeline": [
            {
              "at": "2026-04-15T20:10:00",
              "remaining_caffeine_mg": 118.4,
              "stage": "likely-disruptive"
            }
          ]
        }
        """.data(using: .utf8)!

        let aiPayload = """
        {
          "mode": "live",
          "generated_at": "2026-04-15T20:10:10",
          "headline": "今日咖啡因偏高",
          "narrative": "今晚更适合切到无咖啡因饮品，把睡前残留往下压。",
          "next_actions": ["今晚改喝无糖茶或白水", "避免再叠加功能饮料"],
          "sleep_note": "睡前残留明显偏高，更容易拖慢入睡。"
        }
        """.data(using: .utf8)!

        let decoder = APICodingFactory.makeDecoder()
        let forecast = try decoder.decode(CaffeineForecastSummary.self, from: forecastPayload)
        let aiBrief = try decoder.decode(DailyAIBriefSummary.self, from: aiPayload)

        XCTAssertEqual(forecast.sleepReadiness, .likelyDisruptive)
        XCTAssertEqual(forecast.timeline.first?.remainingCaffeineMG, 118.4)
        XCTAssertTrue(aiBrief.isLive)
        XCTAssertEqual(aiBrief.nextActions.count, 2)
    }

    func testUserLocalSnapshotRoundTripPreservesTemplatesAndLogs() throws {
        let snapshot = UserLocalSnapshot(
            updatedAt: Date(timeIntervalSince1970: 1_760_000_000),
            preferences: PreviewFixtures.userPreferences,
            userDrinkTemplates: PreviewFixtures.userDrinkTemplates,
            logs: [PreviewFixtures.entries[0]]
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(UserLocalSnapshot.self, from: data)

        XCTAssertEqual(decoded.preferences.sleepHour, PreviewFixtures.userPreferences.sleepHour)
        XCTAssertEqual(decoded.userDrinkTemplates.first?.brand, "我的常喝")
        XCTAssertEqual(decoded.logs.first?.brand, "MANNER")
        XCTAssertEqual(decoded.logs.first?.preparationMethod, .espressoMachine)
    }

    @MainActor
    func testOfflineCacheReplaceAllLogsPreservesBrandAndPreparation() {
        let cache = OfflineCacheStore(inMemory: true)
        let entry = DrinkLogEntry(
            id: "sync-entry-1",
            userID: "preview-user",
            drinkDefinitionID: "americano-iced",
            drinkName: "冰美式",
            category: "咖啡",
            brand: "瑞幸",
            preparationMethod: .espressoMachine,
            consumedAt: Date(timeIntervalSince1970: 1_760_000_500),
            servingLabel: "大杯",
            metrics: IngredientMetrics(caffeineMG: 140, sugarG: 0, caloriesKcal: 8, hydrationML: 360, volumeML: 380),
            source: .catalog
        )

        cache.replaceAllLogs(with: [entry])
        let loaded = cache.loadAllLogs()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.brand, "瑞幸")
        XCTAssertEqual(loaded.first?.preparationMethod, .espressoMachine)
    }

    @MainActor
    func testUserDrinkTemplateLifecycleSupportsUpdateAndDelete() {
        let environment = AppEnvironment()
        let initialCount = environment.userDrinkTemplates.count

        environment.addUserDrinkTemplate(
            brand: "测试品牌",
            name: "测试冷萃",
            category: "咖啡",
            caffeineMG: 96,
            sugarG: 0,
            volumeML: 300,
            preparationMethod: .readyToDrink
        )

        guard let created = environment.userDrinkTemplates.first else {
            XCTFail("Expected created template")
            return
        }

        environment.updateUserDrinkTemplate(
            id: created.id,
            brand: "测试品牌",
            name: "测试冷萃升级版",
            category: "咖啡",
            caffeineMG: 108,
            sugarG: 2,
            volumeML: 360,
            preparationMethod: .handBrew
        )

        XCTAssertEqual(environment.userDrinkTemplates.first?.name, "测试冷萃升级版")
        XCTAssertEqual(environment.userDrinkTemplates.first?.volumeML, 360)
        XCTAssertEqual(environment.userDrinkTemplates.first?.preparationMethod, .handBrew)

        environment.deleteUserDrinkTemplate(id: created.id)

        XCTAssertEqual(environment.userDrinkTemplates.count, initialCount)
        XCTAssertFalse(environment.userDrinkTemplates.contains(where: { $0.id == created.id }))
    }
}

private struct SessionPayloadProbe: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let userID: String
    let displayName: String
    let sync: SyncEnvelopeSummary

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case userID = "user_id"
        case displayName = "display_name"
        case sync
    }
}
