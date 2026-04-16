from __future__ import annotations

from collections import defaultdict
from datetime import date
from typing import Dict, List, Optional, Protocol, runtime_checkable

from app.domain.models import (
    AdminSnapshot,
    AppleAuthRequest,
    BrewCalculatorRequest,
    BrewCalculatorResult,
    BrewRecipe,
    CategoryBreakdown,
    DailyAggregate,
    DrinkDefinition,
    DrinkLogCreateRequest,
    DrinkLogEntry,
    DrinkLogUpdateRequest,
    DrinkServingOption,
    ExportRequest,
    ExportTask,
    FeedbackItem,
    HealthGoals,
    IngredientMetrics,
    RuleToggles,
    SessionResponse,
    UserProfile,
)


def seed_drink_definitions() -> List[DrinkDefinition]:
    return [
        DrinkDefinition(
            id="latte-oat",
            name="燕麦拿铁",
            category="咖啡",
            brand="MANNER",
            brand_collection="城市咖啡",
            tags=["早餐", "办公", "意式机"],
            hero_flavor="燕麦坚果",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            brew_recipe=BrewRecipe(
                method="espresso-machine",
                title="双份意式燕麦拿铁",
                ratio_text="18g 粉 -> 36g 浓缩",
                coffee_g=18,
                output_ml=320,
                milk_ml=230,
                concentrate_ml=36,
                brew_seconds=30,
                temperature_c=93,
                grind_text="意式细研磨",
                tasting_note="适合晨间通勤的坚果甜感",
            ),
            metrics=IngredientMetrics(
                caffeine_mg=120, sugar_g=7, calories_kcal=145, hydration_ml=260, volume_ml=320
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=320, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="pour-over-yirgacheffe",
            name="耶加雪菲手冲",
            category="手冲咖啡",
            brand="Blue Bottle",
            brand_collection="精品咖啡",
            tags=["手冲", "果酸", "单品"],
            hero_flavor="花香柑橘",
            preparation_methods=["hand-brew"],
            brew_recipe=BrewRecipe(
                method="hand-brew",
                title="V60 手冲参考",
                ratio_text="1:16",
                coffee_g=18,
                water_ml=300,
                output_ml=260,
                brew_seconds=195,
                temperature_c=92,
                grind_text="中细研磨",
                tasting_note="适合做开发者页面里的手冲计算演示",
            ),
            metrics=IngredientMetrics(
                caffeine_mg=130, sugar_g=0, calories_kcal=6, hydration_ml=255, volume_ml=260
            ),
            serving_options=[
                DrinkServingOption(id="v60", name="V60 一杯份", volume_ml=260, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="americano-iced",
            name="冰美式",
            category="咖啡",
            brand="瑞幸",
            brand_collection="日常通勤",
            tags=["低糖", "即点", "意式机"],
            hero_flavor="清爽黑咖",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=140, sugar_g=0, calories_kcal=8, hydration_ml=360, volume_ml=380
            ),
            serving_options=[
                DrinkServingOption(id="large", name="大杯", volume_ml=380, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="luckin-coconut-latte",
            name="生椰拿铁",
            category="咖啡",
            brand="瑞幸",
            brand_collection="日常通勤",
            tags=["椰乳", "奶咖", "高频"],
            hero_flavor="生椰奶香",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=126, sugar_g=10, calories_kcal=168, hydration_ml=285, volume_ml=320
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="中杯", volume_ml=320, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="luckin-velvet-latte",
            name="丝绒拿铁",
            category="咖啡",
            brand="瑞幸",
            brand_collection="日常通勤",
            tags=["奶咖", "顺滑", "高频"],
            hero_flavor="奶香可可",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=132, sugar_g=11, calories_kcal=182, hydration_ml=290, volume_ml=340
            ),
            serving_options=[
                DrinkServingOption(id="large", name="大杯", volume_ml=340, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="starbucks-flat-white",
            name="馥芮白",
            category="咖啡",
            brand="星巴克",
            brand_collection="经典意式",
            tags=["奶咖", "意式机", "高频"],
            hero_flavor="浓缩奶香",
            preparation_methods=["espresso-machine"],
            metrics=IngredientMetrics(
                caffeine_mg=130, sugar_g=9, calories_kcal=150, hydration_ml=250, volume_ml=330
            ),
            serving_options=[
                DrinkServingOption(id="tall", name="中杯", volume_ml=330, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="starbucks-americano",
            name="美式咖啡",
            category="咖啡",
            brand="星巴克",
            brand_collection="经典意式",
            tags=["黑咖", "意式机", "高频"],
            hero_flavor="坚果焦糖",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=150, sugar_g=0, calories_kcal=10, hydration_ml=340, volume_ml=355
            ),
            serving_options=[
                DrinkServingOption(id="tall", name="中杯", volume_ml=355, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="starbucks-shaken-oat-latte",
            name="冰摇浓缩燕麦拿铁",
            category="咖啡",
            brand="星巴克",
            brand_collection="经典意式",
            tags=["燕麦", "冰咖", "奶咖"],
            hero_flavor="燕麦焦糖",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=145, sugar_g=9, calories_kcal=148, hydration_ml=285, volume_ml=350
            ),
            serving_options=[
                DrinkServingOption(id="grande", name="大杯", volume_ml=350, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="cotti-coconut-latte",
            name="生椰米乳拿铁",
            category="咖啡",
            brand="库迪",
            brand_collection="日常通勤",
            tags=["奶咖", "通勤", "椰香"],
            hero_flavor="椰乳谷物",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=118, sugar_g=11, calories_kcal=182, hydration_ml=285, volume_ml=360
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=360, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="cotti-orange-americano",
            name="橙C美式",
            category="咖啡",
            brand="库迪",
            brand_collection="日常通勤",
            tags=["果咖", "美式", "高频"],
            hero_flavor="橙香黑咖",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=136, sugar_g=6, calories_kcal=84, hydration_ml=320, volume_ml=420
            ),
            serving_options=[
                DrinkServingOption(id="large", name="大杯", volume_ml=420, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="cotti-latte",
            name="拿铁",
            category="咖啡",
            brand="库迪",
            brand_collection="日常通勤",
            tags=["奶咖", "通勤", "基础款"],
            hero_flavor="牛奶坚果",
            preparation_methods=["espresso-machine", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=122, sugar_g=8, calories_kcal=146, hydration_ml=270, volume_ml=320
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="中杯", volume_ml=320, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="bo-ya-jue-xian",
            name="伯牙绝弦",
            category="奶茶",
            brand="霸王茶姬",
            brand_collection="招牌奶茶",
            tags=["乌龙", "奶茶", "品牌款"],
            hero_flavor="茶香奶韵",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=82, sugar_g=22, calories_kcal=240, hydration_ml=430, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="less-sugar", name="少糖", volume_ml=500, multiplier=0.9)
            ],
        ),
        DrinkDefinition(
            id="chagee-flower-oolong",
            name="花田乌龙",
            category="奶茶",
            brand="霸王茶姬",
            brand_collection="东方茶饮",
            tags=["乌龙", "轻乳", "高频"],
            hero_flavor="花香乌龙",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=66, sugar_g=20, calories_kcal=198, hydration_ml=438, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=500, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="chagee-white-mist",
            name="白雾红尘",
            category="奶茶",
            brand="霸王茶姬",
            brand_collection="东方茶饮",
            tags=["红茶", "奶茶", "丝滑"],
            hero_flavor="红茶奶香",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=60, sugar_g=23, calories_kcal=212, hydration_ml=430, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="less-sugar", name="少糖", volume_ml=500, multiplier=0.88)
            ],
        ),
        DrinkDefinition(
            id="grape-jasmine",
            name="多肉葡萄",
            category="果茶",
            brand="喜茶",
            brand_collection="果茶",
            tags=["果茶", "高频", "品牌款"],
            hero_flavor="葡萄茉莉",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=28, sugar_g=26, calories_kcal=210, hydration_ml=420, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=500, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="heytea-cheese-grape",
            name="轻芝多肉葡萄",
            category="果茶",
            brand="喜茶",
            brand_collection="果茶",
            tags=["芝士", "葡萄", "高频"],
            hero_flavor="葡萄芝香",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=30, sugar_g=24, calories_kcal=228, hydration_ml=415, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=500, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="heytea-black-sugar-bobo",
            name="烤黑糖波波牛乳",
            category="奶茶",
            brand="喜茶",
            brand_collection="经典奶茶",
            tags=["黑糖", "波波", "牛乳"],
            hero_flavor="黑糖焦香",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=36, sugar_g=31, calories_kcal=286, hydration_ml=388, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=500, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="alittle-boba-milk-tea",
            name="波霸奶茶",
            category="奶茶",
            brand="一点点",
            brand_collection="经典奶茶",
            tags=["珍珠", "奶茶", "高频"],
            hero_flavor="红茶奶香",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=54, sugar_g=32, calories_kcal=298, hydration_ml=400, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=500, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="alittle-four-season-macchiato",
            name="四季春玛奇朵",
            category="奶茶",
            brand="一点点",
            brand_collection="清爽茶乳",
            tags=["四季春", "奶盖", "高频"],
            hero_flavor="奶盖青茶",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=46, sugar_g=20, calories_kcal=176, hydration_ml=430, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="less-sugar", name="少糖", volume_ml=500, multiplier=0.88)
            ],
        ),
        DrinkDefinition(
            id="alittle-oolong-milk-tea",
            name="乌龙奶茶",
            category="奶茶",
            brand="一点点",
            brand_collection="经典奶茶",
            tags=["乌龙", "奶茶", "经典"],
            hero_flavor="焙香乌龙",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=58, sugar_g=26, calories_kcal=232, hydration_ml=418, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="regular", name="标准杯", volume_ml=500, multiplier=1.0)
            ],
        ),
    ]


def seed_feedback_items() -> List[FeedbackItem]:
    return [
        FeedbackItem(
            id="feedback-1",
            user_id="demo-user",
            category="catalog",
            content="希望补充更多连锁奶茶品牌",
        ),
        FeedbackItem(
            id="feedback-2",
            user_id="demo-user",
            category="ux",
            content="首页数字很多，但层级还不够清晰，想先看到结论再看解释。",
        ),
        FeedbackItem(
            id="feedback-3",
            user_id="demo-user",
            category="recommendation",
            content="想要一个开发者 support 页面，方便直接看规则和 LLM 联调状态。",
        ),
    ]


def default_rule_toggles() -> RuleToggles:
    return RuleToggles()


def build_daily_aggregate(day: date, entries: List[DrinkLogEntry]) -> DailyAggregate:
    totals = IngredientMetrics()
    breakdown_source: Dict[str, Dict[str, float]] = defaultdict(lambda: {"count": 0, "hydration": 0.0})
    for entry in entries:
        totals = totals.add(entry.metrics)
        breakdown_source[entry.category]["count"] += 1
        breakdown_source[entry.category]["hydration"] += entry.metrics.hydration_ml

    category_breakdown = [
        CategoryBreakdown(
            category=category,
            entries_count=int(values["count"]),
            hydration_ml=round(values["hydration"], 2),
        )
        for category, values in sorted(breakdown_source.items())
    ]
    return DailyAggregate(
        date=day,
        totals=totals,
        entries_count=len(entries),
        category_breakdown=category_breakdown,
    )


@runtime_checkable
class AppRepository(Protocol):
    @property
    def rule_toggles(self) -> RuleToggles:
        ...

    def exchange_apple_token(self, request: AppleAuthRequest) -> SessionResponse:
        ...

    def get_profile(self, user_id: str) -> UserProfile:
        ...

    def save_profile(self, user_id: str, profile: UserProfile) -> UserProfile:
        ...

    def get_goals(self, user_id: str) -> HealthGoals:
        ...

    def save_goals(self, user_id: str, goals: HealthGoals) -> HealthGoals:
        ...

    def search_drink_definitions(
        self,
        query: str = "",
        category: Optional[str] = None,
        brand: Optional[str] = None,
        preparation_method: Optional[str] = None,
    ) -> List[DrinkDefinition]:
        ...

    def get_drink_definition(self, drink_definition_id: str) -> DrinkDefinition:
        ...

    def estimate_brew(self, payload: BrewCalculatorRequest) -> BrewCalculatorResult:
        ...

    def create_log(self, user_id: str, payload: DrinkLogCreateRequest) -> DrinkLogEntry:
        ...

    def list_logs(self, user_id: str, day: Optional[date] = None) -> List[DrinkLogEntry]:
        ...

    def update_log(self, user_id: str, entry_id: str, payload: DrinkLogUpdateRequest) -> DrinkLogEntry:
        ...

    def delete_log(self, user_id: str, entry_id: str) -> None:
        ...

    def get_daily_aggregate(self, user_id: str, day: date) -> DailyAggregate:
        ...

    def create_export(self, request: ExportRequest) -> ExportTask:
        ...

    def get_admin_snapshot(self) -> AdminSnapshot:
        ...

    def list_feedback(self) -> List[FeedbackItem]:
        ...

    def mark_feedback_reviewed(self, feedback_id: str) -> FeedbackItem:
        ...

    def update_rule_toggles(self, toggles: RuleToggles) -> RuleToggles:
        ...
