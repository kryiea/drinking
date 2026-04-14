from __future__ import annotations

from pathlib import Path
from typing import Callable

from sqlalchemy import Engine, create_engine, inspect, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.domain.repository import default_rule_toggles, seed_drink_definitions, seed_feedback_items
from app.persistence.models import (
    Base,
    DrinkDefinitionRow,
    DrinkServingOptionRow,
    FeedbackItemRow,
    RuleToggleRow,
    serialize_tags,
)

SessionFactory = Callable[[], Session]


def build_engine(database_url: str, echo: bool = False) -> Engine:
    url = make_url(database_url)
    connect_args = {}
    engine_kwargs = {"echo": echo, "future": True}

    if url.get_backend_name().startswith("sqlite"):
        connect_args["check_same_thread"] = False
        if url.database and url.database not in {"", ":memory:"}:
            Path(url.database).parent.mkdir(parents=True, exist_ok=True)
        if database_url in {"sqlite://", "sqlite+pysqlite://"} or ":memory:" in database_url:
            engine_kwargs["poolclass"] = StaticPool

    if connect_args:
        engine_kwargs["connect_args"] = connect_args

    return create_engine(database_url, **engine_kwargs)


def make_session_factory(engine: Engine) -> sessionmaker[Session]:
    return sessionmaker(bind=engine, autocommit=False, autoflush=False, expire_on_commit=False)


def init_database(engine: Engine) -> None:
    Base.metadata.create_all(bind=engine)
    apply_schema_updates(engine)


def apply_schema_updates(engine: Engine) -> None:
    inspector = inspect(engine)

    add_missing_columns(
        engine,
        inspector,
        "drink_definitions",
        {
            "brand_collection": "VARCHAR(120)",
            "hero_flavor": "VARCHAR(120)",
            "preparation_methods": "JSON",
            "brew_recipe": "JSON",
            "featured_order": "INTEGER DEFAULT 0",
        },
    )
    add_missing_columns(
        engine,
        inspector,
        "drink_logs",
        {
            "brand": "VARCHAR(120)",
            "preparation_method": "VARCHAR(40)",
        },
    )


def add_missing_columns(
    engine: Engine,
    inspector,
    table_name: str,
    desired_columns: dict[str, str],
) -> None:
    if inspector.has_table(table_name) is False:
        return

    existing = {column["name"] for column in inspector.get_columns(table_name)}
    with engine.begin() as connection:
        for column_name, ddl in desired_columns.items():
            if column_name in existing:
                continue
            connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {ddl}"))


def seed_database(session: Session) -> None:
    for index, definition in enumerate(seed_drink_definitions()):
        definition_row = session.get(DrinkDefinitionRow, definition.id)
        if definition_row is None:
            definition_row = DrinkDefinitionRow(id=definition.id)
            session.add(definition_row)

        definition_row.name = definition.name
        definition_row.category = definition.category
        definition_row.brand = definition.brand
        definition_row.brand_collection = definition.brand_collection
        definition_row.tags = serialize_tags(definition.tags)
        definition_row.hero_flavor = definition.hero_flavor
        definition_row.preparation_methods = list(definition.preparation_methods)
        definition_row.brew_recipe = definition.brew_recipe.model_dump() if definition.brew_recipe else None
        definition_row.featured_order = index
        definition_row.caffeine_mg = definition.metrics.caffeine_mg
        definition_row.sugar_g = definition.metrics.sugar_g
        definition_row.calories_kcal = definition.metrics.calories_kcal
        definition_row.hydration_ml = definition.metrics.hydration_ml
        definition_row.volume_ml = definition.metrics.volume_ml
        definition_row.template_source = definition.template_source
        definition_row.serving_options = [
            DrinkServingOptionRow(
                option_id=option.id,
                name=option.name,
                volume_ml=option.volume_ml,
                multiplier=option.multiplier,
                sort_order=option_index,
            )
            for option_index, option in enumerate(definition.serving_options)
        ]

    for item in seed_feedback_items():
        feedback_row = session.get(FeedbackItemRow, item.id)
        if feedback_row is None:
            feedback_row = FeedbackItemRow(id=item.id)
            session.add(feedback_row)
        feedback_row.user_id = item.user_id
        feedback_row.category = item.category
        feedback_row.content = item.content
        feedback_row.status = item.status

    if session.query(RuleToggleRow).count() == 0:
        toggles = default_rule_toggles()
        session.add(
            RuleToggleRow(
                id="default",
                caffeine_warning_ratio=toggles.caffeine_warning_ratio,
                sugar_warning_ratio=toggles.sugar_warning_ratio,
                late_caffeine_hour=toggles.late_caffeine_hour,
                enabled_rules=list(toggles.enabled_rules),
            )
        )

    session.commit()
