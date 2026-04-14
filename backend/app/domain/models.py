from __future__ import annotations

from datetime import date, datetime, time
from typing import Dict, List, Literal, Optional, Union

from pydantic import BaseModel, Field

PreparationMethod = Literal[
    "hand-brew",
    "espresso-machine",
    "milk-tea",
    "sparkling",
    "ready-to-drink",
]
BrewStrength = Literal["light", "balanced", "bold"]


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


class BrewRecipe(BaseModel):
    method: PreparationMethod
    title: str
    ratio_text: str
    coffee_g: float = 0
    water_ml: float = 0
    output_ml: float = 0
    milk_ml: float = 0
    concentrate_ml: float = 0
    brew_seconds: int = 0
    temperature_c: int = 0
    grind_text: Optional[str] = None
    tasting_note: Optional[str] = None


class DrinkDefinition(BaseModel):
    id: str
    name: str
    category: str
    brand: str
    brand_collection: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    hero_flavor: Optional[str] = None
    preparation_methods: List[PreparationMethod] = Field(default_factory=list)
    brew_recipe: Optional[BrewRecipe] = None
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
    brand: Optional[str] = None
    preparation_method: Optional[PreparationMethod] = None
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


class BrewCalculatorRequest(BaseModel):
    drink_definition_id: str
    target_volume_ml: int = Field(default=320, ge=60, le=1000)
    strength: BrewStrength = "balanced"


class BrewCalculatorResult(BaseModel):
    drink_definition_id: str
    drink_name: str
    brand: str
    method: PreparationMethod
    target_volume_ml: int
    coffee_g: float
    water_ml: float
    output_ml: float
    milk_ml: float = 0
    concentrate_ml: float = 0
    brew_ratio: str
    summary: str
    tasting_note: Optional[str] = None


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
    brand_count: int = 0
    rule_toggles: RuleToggles
    pending_feedback: int


class ServiceStatus(BaseModel):
    name: str
    target: str
    state: Literal["ready", "configured", "disabled"]
    detail: str


class LLMProviderStatus(BaseModel):
    configured: bool
    provider: str
    base_url: Optional[str] = None
    model: Optional[str] = None
    mode: Literal["ready", "not-configured"] = "not-configured"


class SupportPlatformSnapshot(BaseModel):
    admin: AdminSnapshot
    llm: LLMProviderStatus
    services: List[ServiceStatus] = Field(default_factory=list)
    recent_feedback: List[FeedbackItem] = Field(default_factory=list)


class LLMPreviewRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=2000)
    system_prompt: Optional[str] = "你是饮知开发期的运营支持助手，请用简洁、专业、可执行的中文回答。"
    temperature: Optional[float] = Field(default=None, ge=0, le=1.5)


class LLMPreviewResponse(BaseModel):
    configured: bool
    provider: str
    model: Optional[str] = None
    mode: Literal["live", "fallback"] = "fallback"
    output: str
