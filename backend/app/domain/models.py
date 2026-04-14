from __future__ import annotations

from datetime import date, datetime, time
from typing import Dict, List, Literal, Optional, Union

from pydantic import BaseModel, Field


class IngredientMetrics(BaseModel):
    caffeine_mg: float = 0
    sugar_g: float = 0
    calories_kcal: float = 0
    hydration_ml: float = 0
    volume_ml: float = 0

    def scaled(self, ratio: float) -> "IngredientMetrics":
        return IngredientMetrics(
            caffeine_mg=round(self.caffeine_mg * ratio, 2),
            sugar_g=round(self.sugar_g * ratio, 2),
            calories_kcal=round(self.calories_kcal * ratio, 2),
            hydration_ml=round(self.hydration_ml * ratio, 2),
            volume_ml=round(self.volume_ml * ratio, 2),
        )

    def add(self, other: "IngredientMetrics") -> "IngredientMetrics":
        return IngredientMetrics(
            caffeine_mg=round(self.caffeine_mg + other.caffeine_mg, 2),
            sugar_g=round(self.sugar_g + other.sugar_g, 2),
            calories_kcal=round(self.calories_kcal + other.calories_kcal, 2),
            hydration_ml=round(self.hydration_ml + other.hydration_ml, 2),
            volume_ml=round(self.volume_ml + other.volume_ml, 2),
        )


class DrinkServingOption(BaseModel):
    id: str
    name: str
    volume_ml: int
    multiplier: float = 1.0


class DrinkDefinition(BaseModel):
    id: str
    name: str
    category: str
    brand: str
    tags: List[str] = Field(default_factory=list)
    metrics: IngredientMetrics
    serving_options: List[DrinkServingOption] = Field(default_factory=list)
    template_source: Literal["seed", "user", "partner"] = "seed"


class DrinkLogCreateRequest(BaseModel):
    drink_definition_id: str
    serving_option_id: Optional[str] = None
    ratio: float = 1.0
    consumed_at: datetime
    note: Optional[str] = None
    source: Literal["catalog", "recent", "favorite", "custom"] = "catalog"


class DrinkLogUpdateRequest(BaseModel):
    ratio: Optional[float] = None
    consumed_at: Optional[datetime] = None
    note: Optional[str] = None


class DrinkLogEntry(BaseModel):
    id: str
    user_id: str
    drink_definition_id: str
    drink_name: str
    category: str
    consumed_at: datetime
    serving_label: str
    metrics: IngredientMetrics
    note: Optional[str] = None
    source: Literal["catalog", "recent", "favorite", "custom"] = "catalog"
    version: int = 1
    sync_status: Literal["synced", "pending", "conflict"] = "synced"


class UserProfile(BaseModel):
    user_id: str
    display_name: str = "饮知用户"
    age: int = 28
    weight_kg: float = 60
    height_cm: float = 168
    sleep_time: time = time(23, 30)
    caffeine_sensitive: bool = False
    blood_sugar_watch: bool = True


class HealthGoals(BaseModel):
    caffeine_limit_mg: float = 300
    sugar_limit_g: float = 25
    calories_limit_kcal: float = 1800
    hydration_goal_ml: float = 2000


class CategoryBreakdown(BaseModel):
    category: str
    entries_count: int
    hydration_ml: float


class DailyAggregate(BaseModel):
    date: date
    totals: IngredientMetrics
    entries_count: int
    category_breakdown: List[CategoryBreakdown]


class RecommendationExplanation(BaseModel):
    rule_id: str
    trigger: str
    inputs: Dict[str, Union[float, str]]
    threshold_comparison: str
    action: str
    risk: str


class RecommendationDecision(BaseModel):
    severity: Literal["info", "warning", "critical"]
    title: str
    summary: str
    explanation: RecommendationExplanation


class SyncEnvelope(BaseModel):
    last_synced_at: Optional[datetime] = None
    pending_entry_ids: List[str] = Field(default_factory=list)
    conflict_count: int = 0


class AppleAuthRequest(BaseModel):
    identity_token: str = Field(min_length=8)
    authorization_code: Optional[str] = None
    device_name: Optional[str] = "iPhone"


class SessionResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 3600
    user_id: str
    display_name: str
    sync: SyncEnvelope


class ExportRequest(BaseModel):
    format: Literal["csv", "pdf"]
    start_date: date
    end_date: date


class ExportTask(BaseModel):
    id: str
    status: Literal["queued", "processing", "ready"] = "queued"
    format: Literal["csv", "pdf"]
    download_url: Optional[str] = None


class RuleToggles(BaseModel):
    caffeine_warning_ratio: float = 0.8
    sugar_warning_ratio: float = 0.8
    late_caffeine_hour: int = 15
    enabled_rules: List[str] = Field(
        default_factory=lambda: ["caffeine-warning", "sugar-warning", "late-caffeine"]
    )


class FeedbackItem(BaseModel):
    id: str
    user_id: str
    category: Literal["catalog", "recommendation", "bug", "ux"]
    content: str
    status: Literal["new", "reviewed"] = "new"


class AdminSnapshot(BaseModel):
    drink_count: int
    rule_toggles: RuleToggles
    pending_feedback: int
