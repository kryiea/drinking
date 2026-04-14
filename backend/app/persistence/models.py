from __future__ import annotations

from datetime import date, datetime, time
from typing import Any, List, Optional

from sqlalchemy import JSON, Boolean, Date, DateTime, Float, ForeignKey, Integer, String, Text, Time
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class DrinkDefinitionRow(Base):
    __tablename__ = "drink_definitions"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(String(60), index=True, nullable=False)
    brand: Mapped[str] = mapped_column(String(120), nullable=False)
    tags: Mapped[List[str]] = mapped_column(JSON, default=list)
    caffeine_mg: Mapped[float] = mapped_column(Float, default=0)
    sugar_g: Mapped[float] = mapped_column(Float, default=0)
    calories_kcal: Mapped[float] = mapped_column(Float, default=0)
    hydration_ml: Mapped[float] = mapped_column(Float, default=0)
    volume_ml: Mapped[float] = mapped_column(Float, default=0)
    template_source: Mapped[str] = mapped_column(String(20), default="seed")

    serving_options: Mapped[List["DrinkServingOptionRow"]] = relationship(
        back_populates="drink_definition",
        cascade="all, delete-orphan",
        order_by="DrinkServingOptionRow.sort_order",
    )


class DrinkServingOptionRow(Base):
    __tablename__ = "drink_serving_options"

    pk: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    drink_definition_id: Mapped[str] = mapped_column(
        ForeignKey("drink_definitions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    option_id: Mapped[str] = mapped_column(String(80), nullable=False)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    volume_ml: Mapped[int] = mapped_column(Integer, nullable=False)
    multiplier: Mapped[float] = mapped_column(Float, default=1.0)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    drink_definition: Mapped[DrinkDefinitionRow] = relationship(back_populates="serving_options")


class UserProfileRow(Base):
    __tablename__ = "user_profiles"

    user_id: Mapped[str] = mapped_column(String(80), primary_key=True)
    display_name: Mapped[str] = mapped_column(String(80), default="饮知用户")
    age: Mapped[int] = mapped_column(Integer, default=28)
    weight_kg: Mapped[float] = mapped_column(Float, default=60)
    height_cm: Mapped[float] = mapped_column(Float, default=168)
    sleep_time: Mapped[time] = mapped_column(Time, default=time(23, 30))
    caffeine_sensitive: Mapped[bool] = mapped_column(Boolean, default=False)
    blood_sugar_watch: Mapped[bool] = mapped_column(Boolean, default=True)


class HealthGoalsRow(Base):
    __tablename__ = "health_goals"

    user_id: Mapped[str] = mapped_column(String(80), primary_key=True)
    caffeine_limit_mg: Mapped[float] = mapped_column(Float, default=300)
    sugar_limit_g: Mapped[float] = mapped_column(Float, default=25)
    calories_limit_kcal: Mapped[float] = mapped_column(Float, default=1800)
    hydration_goal_ml: Mapped[float] = mapped_column(Float, default=2000)


class DrinkLogRow(Base):
    __tablename__ = "drink_logs"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(80), index=True, nullable=False)
    drink_definition_id: Mapped[str] = mapped_column(String(80), ForeignKey("drink_definitions.id"), nullable=False)
    serving_option_id: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    drink_name: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(String(60), index=True, nullable=False)
    consumed_at: Mapped[datetime] = mapped_column(DateTime, index=True, nullable=False)
    serving_label: Mapped[str] = mapped_column(String(80), nullable=False)
    caffeine_mg: Mapped[float] = mapped_column(Float, default=0)
    sugar_g: Mapped[float] = mapped_column(Float, default=0)
    calories_kcal: Mapped[float] = mapped_column(Float, default=0)
    hydration_ml: Mapped[float] = mapped_column(Float, default=0)
    volume_ml: Mapped[float] = mapped_column(Float, default=0)
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(String(20), default="catalog")
    version: Mapped[int] = mapped_column(Integer, default=1)
    sync_status: Mapped[str] = mapped_column(String(20), default="synced")


class ExportTaskRow(Base):
    __tablename__ = "export_tasks"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    status: Mapped[str] = mapped_column(String(20), default="queued")
    format: Mapped[str] = mapped_column(String(10), nullable=False)
    download_url: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class FeedbackItemRow(Base):
    __tablename__ = "feedback_items"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(80), index=True, nullable=False)
    category: Mapped[str] = mapped_column(String(30), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="new")


class RuleToggleRow(Base):
    __tablename__ = "rule_toggles"

    id: Mapped[str] = mapped_column(String(20), primary_key=True, default="default")
    caffeine_warning_ratio: Mapped[float] = mapped_column(Float, default=0.8)
    sugar_warning_ratio: Mapped[float] = mapped_column(Float, default=0.8)
    late_caffeine_hour: Mapped[int] = mapped_column(Integer, default=15)
    enabled_rules: Mapped[List[str]] = mapped_column(JSON, default=list)


def serialize_tags(tags: Optional[List[str]]) -> List[str]:
    return list(tags or [])


def ensure_list(value: Any) -> List[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    return []
