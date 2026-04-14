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
