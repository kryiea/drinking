from __future__ import annotations

from datetime import date, datetime, time, timedelta
from typing import List, Optional
from uuid import uuid4

from sqlalchemy import String, cast, func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.domain.models import (
    AdminSnapshot,
    AppleAuthRequest,
    BrewCalculatorRequest,
    BrewCalculatorResult,
    BrewRecipe,
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
    SyncEnvelope,
    UserProfile,
)
from app.domain.repository import AppRepository, build_daily_aggregate, default_rule_toggles
from app.persistence.models import (
    DrinkDefinitionRow,
    DrinkLogRow,
    DrinkServingOptionRow,
    ExportTaskRow,
    FeedbackItemRow,
    HealthGoalsRow,
    RuleToggleRow,
    UserProfileRow,
    ensure_list,
)


class SQLAlchemyRepository(AppRepository):
    def __init__(self, session: Session) -> None:
        self.session = session

    @property
    def rule_toggles(self) -> RuleToggles:
        row = self.session.get(RuleToggleRow, "default")
        if row is None:
            toggles = default_rule_toggles()
            row = RuleToggleRow(
                id="default",
                caffeine_warning_ratio=toggles.caffeine_warning_ratio,
                sugar_warning_ratio=toggles.sugar_warning_ratio,
                late_caffeine_hour=toggles.late_caffeine_hour,
                enabled_rules=list(toggles.enabled_rules),
            )
            self.session.add(row)
            self.session.commit()
            self.session.refresh(row)
        return _rule_row_to_model(row)

    def exchange_apple_token(self, request: AppleAuthRequest) -> SessionResponse:
        user_id = "apple-" + request.identity_token[-8:]
        profile_row = self.session.get(UserProfileRow, user_id)
        if profile_row is None:
            profile_row = UserProfileRow(user_id=user_id)
            self.session.add(profile_row)

        goals_row = self.session.get(HealthGoalsRow, user_id)
        if goals_row is None:
            goals_row = HealthGoalsRow(user_id=user_id)
            self.session.add(goals_row)

        self.session.commit()
        sync = SyncEnvelope(last_synced_at=datetime.utcnow() - timedelta(minutes=2))
        return SessionResponse(
            access_token="demo-session-" + request.identity_token[-12:],
            user_id=user_id,
            display_name=profile_row.display_name,
            sync=sync,
        )

    def get_profile(self, user_id: str) -> UserProfile:
        row = self.session.get(UserProfileRow, user_id)
        if row is None:
            row = UserProfileRow(user_id=user_id)
            self.session.add(row)
            self.session.commit()
            self.session.refresh(row)
        return _profile_row_to_model(row)

    def save_profile(self, user_id: str, profile: UserProfile) -> UserProfile:
        row = self.session.get(UserProfileRow, user_id)
        if row is None:
            row = UserProfileRow(user_id=user_id)
            self.session.add(row)

        row.display_name = profile.display_name
        row.age = profile.age
        row.weight_kg = profile.weight_kg
        row.height_cm = profile.height_cm
        row.sleep_time = profile.sleep_time
        row.caffeine_sensitive = profile.caffeine_sensitive
        row.blood_sugar_watch = profile.blood_sugar_watch
        self.session.commit()
        self.session.refresh(row)
        return _profile_row_to_model(row)

    def get_goals(self, user_id: str) -> HealthGoals:
        row = self.session.get(HealthGoalsRow, user_id)
        if row is None:
            row = HealthGoalsRow(user_id=user_id)
            self.session.add(row)
            self.session.commit()
            self.session.refresh(row)
        return _goals_row_to_model(row)

    def save_goals(self, user_id: str, goals: HealthGoals) -> HealthGoals:
        row = self.session.get(HealthGoalsRow, user_id)
        if row is None:
            row = HealthGoalsRow(user_id=user_id)
            self.session.add(row)

        row.caffeine_limit_mg = goals.caffeine_limit_mg
        row.sugar_limit_g = goals.sugar_limit_g
        row.calories_limit_kcal = goals.calories_limit_kcal
        row.hydration_goal_ml = goals.hydration_goal_ml
        self.session.commit()
        self.session.refresh(row)
        return _goals_row_to_model(row)

    def search_drink_definitions(
        self,
        query: str = "",
        category: Optional[str] = None,
        brand: Optional[str] = None,
        preparation_method: Optional[str] = None,
    ) -> List[DrinkDefinition]:
        statement = (
            select(DrinkDefinitionRow)
            .options(joinedload(DrinkDefinitionRow.serving_options))
            .order_by(DrinkDefinitionRow.featured_order.asc(), DrinkDefinitionRow.category.asc(), DrinkDefinitionRow.name.asc())
        )
        if category:
            statement = statement.where(DrinkDefinitionRow.category == category)
        if brand:
            statement = statement.where(func.lower(DrinkDefinitionRow.brand) == brand.lower())
        if preparation_method:
            statement = statement.where(
                func.lower(cast(DrinkDefinitionRow.preparation_methods, String)).like(f"%{preparation_method.lower()}%")
            )

        normalized = query.lower().strip()
        if normalized:
            like_pattern = f"%{normalized}%"
            statement = statement.where(
                or_(
                    func.lower(DrinkDefinitionRow.name).like(like_pattern),
                    func.lower(DrinkDefinitionRow.brand).like(like_pattern),
                    func.lower(func.coalesce(DrinkDefinitionRow.brand_collection, "")).like(like_pattern),
                    func.lower(DrinkDefinitionRow.category).like(like_pattern),
                    func.lower(cast(DrinkDefinitionRow.tags, String)).like(like_pattern),
                    func.lower(func.coalesce(DrinkDefinitionRow.hero_flavor, "")).like(like_pattern),
                )
            )

        rows = self.session.execute(statement).unique().scalars().all()
        return [_definition_row_to_model(row) for row in rows]

    def get_drink_definition(self, drink_definition_id: str) -> DrinkDefinition:
        statement = (
            select(DrinkDefinitionRow)
            .options(joinedload(DrinkDefinitionRow.serving_options))
            .where(DrinkDefinitionRow.id == drink_definition_id)
        )
        row = self.session.execute(statement).unique().scalar_one()
        return _definition_row_to_model(row)

    def estimate_brew(self, payload: BrewCalculatorRequest) -> BrewCalculatorResult:
        definition = self.get_drink_definition(payload.drink_definition_id)
        recipe = definition.brew_recipe or _fallback_recipe_for(definition)

        base_output = recipe.output_ml or max(definition.metrics.volume_ml, 1)
        scale = payload.target_volume_ml / max(base_output, 1)
        strength_factor = {"light": 0.92, "balanced": 1.0, "bold": 1.08}[payload.strength]

        coffee_g = round(recipe.coffee_g * scale * strength_factor, 1)
        water_ml = round(recipe.water_ml * scale, 1)
        concentrate_ml = round(recipe.concentrate_ml * scale * strength_factor, 1)
        milk_ml = round(recipe.milk_ml * scale, 1)
        output_ml = float(payload.target_volume_ml)

        summary_parts = [f"{recipe.title} · {payload.target_volume_ml}ml"]
        if coffee_g > 0:
            summary_parts.append(f"咖啡粉 {coffee_g:g}g")
        if water_ml > 0:
            summary_parts.append(f"热水 {water_ml:g}ml")
        if concentrate_ml > 0:
            summary_parts.append(f"浓缩 {concentrate_ml:g}ml")
        if milk_ml > 0:
            summary_parts.append(f"奶基底 {milk_ml:g}ml")

        return BrewCalculatorResult(
            drink_definition_id=definition.id,
            drink_name=definition.name,
            brand=definition.brand,
            method=recipe.method,
            target_volume_ml=payload.target_volume_ml,
            coffee_g=coffee_g,
            water_ml=water_ml,
            output_ml=output_ml,
            milk_ml=milk_ml,
            concentrate_ml=concentrate_ml,
            brew_ratio=recipe.ratio_text,
            summary="，".join(summary_parts),
            tasting_note=recipe.tasting_note,
        )

    def create_log(self, user_id: str, payload: DrinkLogCreateRequest) -> DrinkLogEntry:
        definition_row = self._get_definition_row(payload.drink_definition_id)
        serving_row = self._select_serving_option(definition_row.serving_options, payload.serving_option_id)
        ratio = payload.ratio * serving_row.multiplier
        metrics = IngredientMetrics(
            caffeine_mg=definition_row.caffeine_mg,
            sugar_g=definition_row.sugar_g,
            calories_kcal=definition_row.calories_kcal,
            hydration_ml=definition_row.hydration_ml,
            volume_ml=definition_row.volume_ml,
        ).scaled(ratio)

        row = DrinkLogRow(
            id=str(uuid4()),
            user_id=user_id,
            drink_definition_id=definition_row.id,
            serving_option_id=serving_row.option_id,
            drink_name=definition_row.name,
            category=definition_row.category,
            brand=definition_row.brand,
            preparation_method=ensure_list(definition_row.preparation_methods)[0] if definition_row.preparation_methods else None,
            consumed_at=payload.consumed_at,
            serving_label=serving_row.name,
            caffeine_mg=metrics.caffeine_mg,
            sugar_g=metrics.sugar_g,
            calories_kcal=metrics.calories_kcal,
            hydration_ml=metrics.hydration_ml,
            volume_ml=metrics.volume_ml,
            note=payload.note,
            source=payload.source,
            version=1,
            sync_status="synced",
        )
        self.session.add(row)
        self.session.commit()
        self.session.refresh(row)
        return _log_row_to_model(row)

    def list_logs(self, user_id: str, day: Optional[date] = None) -> List[DrinkLogEntry]:
        statement = select(DrinkLogRow).where(DrinkLogRow.user_id == user_id)
        if day is not None:
            day_start = datetime.combine(day, time.min)
            day_end = day_start + timedelta(days=1)
            statement = statement.where(
                DrinkLogRow.consumed_at >= day_start,
                DrinkLogRow.consumed_at < day_end,
            )
        statement = statement.order_by(DrinkLogRow.consumed_at.desc())
        rows = self.session.execute(statement).scalars().all()
        return [_log_row_to_model(row) for row in rows]

    def update_log(self, user_id: str, entry_id: str, payload: DrinkLogUpdateRequest) -> DrinkLogEntry:
        statement = select(DrinkLogRow).where(DrinkLogRow.user_id == user_id, DrinkLogRow.id == entry_id)
        row = self.session.execute(statement).scalar_one_or_none()
        if row is None:
            raise KeyError(entry_id)

        if payload.ratio is not None:
            definition_row = self._get_definition_row(row.drink_definition_id)
            metrics = IngredientMetrics(
                caffeine_mg=definition_row.caffeine_mg,
                sugar_g=definition_row.sugar_g,
                calories_kcal=definition_row.calories_kcal,
                hydration_ml=definition_row.hydration_ml,
                volume_ml=definition_row.volume_ml,
            ).scaled(payload.ratio)
            row.caffeine_mg = metrics.caffeine_mg
            row.sugar_g = metrics.sugar_g
            row.calories_kcal = metrics.calories_kcal
            row.hydration_ml = metrics.hydration_ml
            row.volume_ml = metrics.volume_ml
            row.serving_label = f"{row.serving_label} x {payload.ratio:g}"

        if payload.consumed_at is not None:
            row.consumed_at = payload.consumed_at
        if payload.note is not None:
            row.note = payload.note

        row.version += 1
        self.session.commit()
        self.session.refresh(row)
        return _log_row_to_model(row)

    def delete_log(self, user_id: str, entry_id: str) -> None:
        statement = select(DrinkLogRow).where(DrinkLogRow.user_id == user_id, DrinkLogRow.id == entry_id)
        row = self.session.execute(statement).scalar_one_or_none()
        if row is None:
            return
        self.session.delete(row)
        self.session.commit()

    def get_daily_aggregate(self, user_id: str, day: date):
        entries = self.list_logs(user_id, day)
        return build_daily_aggregate(day, entries)

    def create_export(self, request: ExportRequest) -> ExportTask:
        row = ExportTaskRow(
            id=str(uuid4()),
            status="ready",
            format=request.format,
            download_url=f"https://example.invalid/exports/{request.format}/{request.start_date.isoformat()}",
            start_date=request.start_date,
            end_date=request.end_date,
        )
        self.session.add(row)
        self.session.commit()
        self.session.refresh(row)
        return ExportTask(
            id=row.id,
            status=row.status,
            format=row.format,
            download_url=row.download_url,
        )

    def get_admin_snapshot(self) -> AdminSnapshot:
        drink_count = self.session.scalar(select(func.count()).select_from(DrinkDefinitionRow)) or 0
        brand_count = self.session.scalar(select(func.count(func.distinct(DrinkDefinitionRow.brand)))) or 0
        pending_feedback = self.session.scalar(
            select(func.count()).select_from(FeedbackItemRow).where(FeedbackItemRow.status == "new")
        ) or 0
        return AdminSnapshot(
            drink_count=int(drink_count),
            brand_count=int(brand_count),
            rule_toggles=self.rule_toggles,
            pending_feedback=int(pending_feedback),
        )

    def list_feedback(self) -> List[FeedbackItem]:
        statement = select(FeedbackItemRow).order_by(FeedbackItemRow.id.asc())
        rows = self.session.execute(statement).scalars().all()
        return [_feedback_row_to_model(row) for row in rows]

    def mark_feedback_reviewed(self, feedback_id: str) -> FeedbackItem:
        row = self.session.get(FeedbackItemRow, feedback_id)
        if row is None:
            raise KeyError(feedback_id)
        row.status = "reviewed"
        self.session.commit()
        self.session.refresh(row)
        return _feedback_row_to_model(row)

    def update_rule_toggles(self, toggles: RuleToggles) -> RuleToggles:
        row = self.session.get(RuleToggleRow, "default")
        if row is None:
            row = RuleToggleRow(id="default")
            self.session.add(row)

        row.caffeine_warning_ratio = toggles.caffeine_warning_ratio
        row.sugar_warning_ratio = toggles.sugar_warning_ratio
        row.late_caffeine_hour = toggles.late_caffeine_hour
        row.enabled_rules = list(toggles.enabled_rules)
        self.session.commit()
        self.session.refresh(row)
        return _rule_row_to_model(row)

    def _get_definition_row(self, drink_definition_id: str) -> DrinkDefinitionRow:
        statement = (
            select(DrinkDefinitionRow)
            .options(joinedload(DrinkDefinitionRow.serving_options))
            .where(DrinkDefinitionRow.id == drink_definition_id)
        )
        return self.session.execute(statement).unique().scalar_one()

    def _select_serving_option(
        self,
        options: List[DrinkServingOptionRow],
        serving_option_id: Optional[str],
    ) -> DrinkServingOptionRow:
        if serving_option_id:
            for option in options:
                if option.option_id == serving_option_id:
                    return option
        return options[0]


def _definition_row_to_model(row: DrinkDefinitionRow) -> DrinkDefinition:
    return DrinkDefinition(
        id=row.id,
        name=row.name,
        category=row.category,
        brand=row.brand,
        brand_collection=row.brand_collection,
        tags=ensure_list(row.tags),
        hero_flavor=row.hero_flavor,
        preparation_methods=ensure_list(row.preparation_methods),
        brew_recipe=_recipe_row_to_model(row.brew_recipe),
        metrics=IngredientMetrics(
            caffeine_mg=row.caffeine_mg,
            sugar_g=row.sugar_g,
            calories_kcal=row.calories_kcal,
            hydration_ml=row.hydration_ml,
            volume_ml=row.volume_ml,
        ),
        serving_options=[
            DrinkServingOption(
                id=option.option_id,
                name=option.name,
                volume_ml=option.volume_ml,
                multiplier=option.multiplier,
            )
            for option in row.serving_options
        ],
        template_source=row.template_source,
    )


def _log_row_to_model(row: DrinkLogRow) -> DrinkLogEntry:
    return DrinkLogEntry(
        id=row.id,
        user_id=row.user_id,
        drink_definition_id=row.drink_definition_id,
        drink_name=row.drink_name,
        category=row.category,
        brand=row.brand,
        preparation_method=row.preparation_method,
        consumed_at=row.consumed_at,
        serving_label=row.serving_label,
        metrics=IngredientMetrics(
            caffeine_mg=row.caffeine_mg,
            sugar_g=row.sugar_g,
            calories_kcal=row.calories_kcal,
            hydration_ml=row.hydration_ml,
            volume_ml=row.volume_ml,
        ),
        note=row.note,
        source=row.source,
        version=row.version,
        sync_status=row.sync_status,
    )


def _profile_row_to_model(row: UserProfileRow) -> UserProfile:
    return UserProfile(
        user_id=row.user_id,
        display_name=row.display_name,
        age=row.age,
        weight_kg=row.weight_kg,
        height_cm=row.height_cm,
        sleep_time=row.sleep_time,
        caffeine_sensitive=row.caffeine_sensitive,
        blood_sugar_watch=row.blood_sugar_watch,
    )


def _goals_row_to_model(row: HealthGoalsRow) -> HealthGoals:
    return HealthGoals(
        caffeine_limit_mg=row.caffeine_limit_mg,
        sugar_limit_g=row.sugar_limit_g,
        calories_limit_kcal=row.calories_limit_kcal,
        hydration_goal_ml=row.hydration_goal_ml,
    )


def _feedback_row_to_model(row: FeedbackItemRow) -> FeedbackItem:
    return FeedbackItem(
        id=row.id,
        user_id=row.user_id,
        category=row.category,
        content=row.content,
        status=row.status,
    )


def _rule_row_to_model(row: RuleToggleRow) -> RuleToggles:
    return RuleToggles(
        caffeine_warning_ratio=row.caffeine_warning_ratio,
        sugar_warning_ratio=row.sugar_warning_ratio,
        late_caffeine_hour=row.late_caffeine_hour,
        enabled_rules=ensure_list(row.enabled_rules),
    )


def _recipe_row_to_model(payload: Optional[dict]) -> Optional[BrewRecipe]:
    if isinstance(payload, dict) is False:
        return None
    return BrewRecipe.model_validate(payload)


def _fallback_recipe_for(definition: DrinkDefinition) -> BrewRecipe:
    methods = definition.preparation_methods or ["ready-to-drink"]
    method = methods[0]
    base_volume = definition.metrics.volume_ml or 300

    if method == "hand-brew":
        return BrewRecipe(
            method="hand-brew",
            title=f"{definition.name} 手冲参考",
            ratio_text="1:16",
            coffee_g=base_volume / 16,
            water_ml=base_volume * 1.15,
            output_ml=base_volume,
            brew_seconds=180,
            temperature_c=92,
            grind_text="中细研磨",
            tasting_note=definition.hero_flavor,
        )

    if method == "espresso-machine":
        return BrewRecipe(
            method="espresso-machine",
            title=f"{definition.name} 意式机参考",
            ratio_text="18g 粉 -> 36g 浓缩",
            coffee_g=18,
            water_ml=max(base_volume - 36, 0),
            output_ml=base_volume,
            concentrate_ml=36,
            milk_ml=max(base_volume - 90, 0),
            brew_seconds=30,
            temperature_c=93,
            grind_text="意式细研磨",
            tasting_note=definition.hero_flavor,
        )

    return BrewRecipe(
        method=method,
        title=f"{definition.name} 标准配方",
        ratio_text="成品即饮",
        output_ml=base_volume,
        tasting_note=definition.hero_flavor,
    )
