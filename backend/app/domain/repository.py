from __future__ import annotations

from collections import defaultdict
from datetime import date
from typing import Dict, List, Optional, Protocol, runtime_checkable

from app.domain.models import (
    AdminSnapshot,
    AppleAuthRequest,
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
            brand="饮知精选",
            tags=["早餐", "办公"],
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
            brand="饮知精选",
            tags=["下午茶", "高糖风险"],
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
            brand="饮知精选",
            tags=["低糖", "补水"],
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
            brand="饮知精选",
            tags=["加班", "高咖啡因"],
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
            brand="饮知精选",
            tags=["维生素", "早餐"],
            metrics=IngredientMetrics(
                caffeine_mg=0, sugar_g=17, calories_kcal=88, hydration_ml=260, volume_ml=280
            ),
            serving_options=[
                DrinkServingOption(id="small", name="小杯", volume_ml=280, multiplier=1.0)
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
        )
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
    ) -> List[DrinkDefinition]:
        ...

    def get_drink_definition(self, drink_definition_id: str) -> DrinkDefinition:
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

    def update_rule_toggles(self, toggles: RuleToggles) -> RuleToggles:
        ...
