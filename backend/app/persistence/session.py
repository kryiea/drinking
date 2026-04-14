from __future__ import annotations

from pathlib import Path
from typing import Callable

from sqlalchemy import Engine, create_engine
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


def seed_database(session: Session) -> None:
    if session.query(DrinkDefinitionRow).count() == 0:
        for definition in seed_drink_definitions():
            definition_row = DrinkDefinitionRow(
                id=definition.id,
                name=definition.name,
                category=definition.category,
                brand=definition.brand,
                tags=serialize_tags(definition.tags),
                caffeine_mg=definition.metrics.caffeine_mg,
                sugar_g=definition.metrics.sugar_g,
                calories_kcal=definition.metrics.calories_kcal,
                hydration_ml=definition.metrics.hydration_ml,
                volume_ml=definition.metrics.volume_ml,
                template_source=definition.template_source,
            )
            definition_row.serving_options = [
                DrinkServingOptionRow(
                    option_id=option.id,
                    name=option.name,
                    volume_ml=option.volume_ml,
                    multiplier=option.multiplier,
                    sort_order=index,
                )
                for index, option in enumerate(definition.serving_options)
            ]
            session.add(definition_row)

    if session.query(FeedbackItemRow).count() == 0:
        for item in seed_feedback_items():
            session.add(
                FeedbackItemRow(
                    id=item.id,
                    user_id=item.user_id,
                    category=item.category,
                    content=item.content,
                    status=item.status,
                )
            )

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
