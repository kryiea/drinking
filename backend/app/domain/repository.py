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
                DrinkServingOption(id="regular", name="标准杯", volume_ml=320, multiplier=1.0),
                DrinkServingOption(id="large", name="大杯", volume_ml=420, multiplier=1.3),
            ],
        ),
        DrinkDefinition(
            id="jasmine-milk-tea",
            name="茉莉奶绿",
            category="奶茶",
            brand="霸王茶姬",
            brand_collection="东方茶饮",
            tags=["下午茶", "高糖风险", "品牌款"],
            hero_flavor="茉莉鲜奶",
            preparation_methods=["milk-tea", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=55, sugar_g=28, calories_kcal=265, hydration_ml=480, volume_ml=500
            ),
            serving_options=[
                DrinkServingOption(id="normal", name="常规糖", volume_ml=500, multiplier=1.0),
                DrinkServingOption(id="half-sugar", name="半糖", volume_ml=500, multiplier=0.78),
            ],
        ),
        DrinkDefinition(
            id="sparkling-water",
            name="青柠气泡水",
            category="气泡饮",
            brand="元气森林",
            brand_collection="轻负担补水",
            tags=["低糖", "补水", "即饮"],
            hero_flavor="青柠清爽",
            preparation_methods=["sparkling", "ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=0, sugar_g=1, calories_kcal=12, hydration_ml=330, volume_ml=330
            ),
            serving_options=[
                DrinkServingOption(id="can", name="一听", volume_ml=330, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="energy-shot",
            name="能量饮料",
            category="功能饮料",
            brand="东鹏特饮",
            brand_collection="高刺激补能",
            tags=["加班", "高咖啡因", "即饮"],
            hero_flavor="高刺激提神",
            preparation_methods=["ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=180, sugar_g=24, calories_kcal=165, hydration_ml=250, volume_ml=250
            ),
            serving_options=[
                DrinkServingOption(id="bottle", name="标准瓶", volume_ml=250, multiplier=1.0)
            ],
        ),
        DrinkDefinition(
            id="fresh-orange",
            name="鲜榨橙汁",
            category="果汁",
            brand="盒马鲜制",
            brand_collection="鲜榨果蔬",
            tags=["维生素", "早餐", "即饮"],
            hero_flavor="清甜果香",
            preparation_methods=["ready-to-drink"],
            metrics=IngredientMetrics(
                caffeine_mg=0, sugar_g=17, calories_kcal=88, hydration_ml=260, volume_ml=280
            ),
            serving_options=[
                DrinkServingOption(id="small", name="小杯", volume_ml=280, multiplier=1.0)
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
                DrinkServingOption(id="v60", name="V60 一杯份", volume_ml=260, multiplier=1.0),
                DrinkServingOption(id="share", name="分享壶", volume_ml=520, multiplier=2.0),
            ],
        ),
        DrinkDefinition(
            id="americano-seesaw",
            name="双份美式",
            category="咖啡",
            brand="Seesaw",
            brand_collection="城市咖啡",
            tags=["意式机", "办公", "高咖啡因"],
            hero_flavor="坚果可可",
            preparation_methods=["espresso-machine"],
            brew_recipe=BrewRecipe(
                method="espresso-machine",
                title="双份意式美式",
                ratio_text="18g 粉 -> 36g 浓缩",
                coffee_g=18,
                water_ml=180,
                output_ml=240,
                concentrate_ml=36,
                brew_seconds=28,
                temperature_c=93,
                grind_text="意式细研磨",
                tasting_note="适合下午高强度编码前的小杯快提神",
            ),
            metrics=IngredientMetrics(
                caffeine_mg=145, sugar_g=0, calories_kcal=8, hydration_ml=220, volume_ml=240
            ),
            serving_options=[
                DrinkServingOption(id="double", name="双份", volume_ml=240, multiplier=1.0),
                DrinkServingOption(id="large", name="大杯", volume_ml=360, multiplier=1.45),
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
