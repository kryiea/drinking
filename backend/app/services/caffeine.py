from __future__ import annotations

from datetime import datetime, time, timedelta
from math import exp, log

from app.domain.models import CaffeineForecast, CaffeineForecastPoint, DrinkLogEntry, SleepReadiness, UserProfile


def build_caffeine_forecast(
    entries: list[DrinkLogEntry],
    profile: UserProfile,
    *,
    now: datetime | None = None,
) -> CaffeineForecast:
    calculated_at = now or datetime.now()
    sleep_at = _next_sleep_datetime(profile.sleep_time, calculated_at)
    half_life_hours = _estimate_half_life_hours(profile)
    safe_threshold_mg = 20.0 if profile.caffeine_sensitive else 35.0

    caffeine_entries = [
        entry
        for entry in entries
        if entry.metrics.caffeine_mg > 0 and entry.consumed_at <= calculated_at + timedelta(hours=18)
    ]

    current_estimate = _remaining_caffeine(caffeine_entries, calculated_at, half_life_hours)
    projected_sleep = _remaining_caffeine(caffeine_entries, sleep_at, half_life_hours)
    readiness = _sleep_stage(projected_sleep, safe_threshold_mg)
    recommended_sleep_time = _find_sleep_ready_time(
        caffeine_entries,
        start=calculated_at,
        threshold_mg=safe_threshold_mg,
        half_life_hours=half_life_hours,
    )

    timeline_anchor = max(sleep_at, calculated_at + timedelta(hours=4))
    timeline_end = min(timeline_anchor + timedelta(hours=4), calculated_at + timedelta(hours=12))
    timeline = _build_timeline(
        caffeine_entries,
        start=calculated_at,
        end=timeline_end,
        half_life_hours=half_life_hours,
        safe_threshold_mg=safe_threshold_mg,
    )

    summary = _build_summary(
        sleep_at=sleep_at,
        projected_sleep_mg=projected_sleep,
        readiness=readiness,
        recommended_sleep_time=recommended_sleep_time,
    )
    sleep_impact = _build_sleep_impact(
        readiness=readiness,
        safe_threshold_mg=safe_threshold_mg,
        projected_sleep_mg=projected_sleep,
    )

    return CaffeineForecast(
        calculated_at=calculated_at,
        sleep_at=sleep_at,
        half_life_hours=round(half_life_hours, 1),
        current_estimate_mg=round(current_estimate, 1),
        projected_sleep_mg=round(projected_sleep, 1),
        safe_sleep_threshold_mg=safe_threshold_mg,
        recommended_sleep_time=recommended_sleep_time,
        sleep_readiness=readiness,
        summary=summary,
        sleep_impact=sleep_impact,
        timeline=timeline,
    )


def _estimate_half_life_hours(profile: UserProfile) -> float:
    return 7.0 if profile.caffeine_sensitive else 5.0


def _next_sleep_datetime(sleep_time: time, now: datetime) -> datetime:
    candidate = datetime.combine(now.date(), sleep_time)
    if candidate <= now:
        candidate += timedelta(days=1)
    return candidate


def _remaining_caffeine(entries: list[DrinkLogEntry], at: datetime, half_life_hours: float) -> float:
    total = 0.0
    rate = log(2) / half_life_hours

    for entry in entries:
        if entry.consumed_at > at:
            continue
        elapsed_hours = max((at - entry.consumed_at).total_seconds() / 3600, 0)
        total += entry.metrics.caffeine_mg * exp(-rate * elapsed_hours)

    return total


def _sleep_stage(remaining_mg: float, safe_threshold_mg: float) -> SleepReadiness:
    if remaining_mg <= safe_threshold_mg:
        return "sleep-friendly"
    if remaining_mg <= safe_threshold_mg * 2:
        return "watch"
    return "likely-disruptive"


def _find_sleep_ready_time(
    entries: list[DrinkLogEntry],
    *,
    start: datetime,
    threshold_mg: float,
    half_life_hours: float,
) -> datetime | None:
    if _remaining_caffeine(entries, start, half_life_hours) <= threshold_mg:
        return start

    for step in range(1, 73):
        candidate = start + timedelta(minutes=30 * step)
        if _remaining_caffeine(entries, candidate, half_life_hours) <= threshold_mg:
            return candidate

    return None


def _build_timeline(
    entries: list[DrinkLogEntry],
    *,
    start: datetime,
    end: datetime,
    half_life_hours: float,
    safe_threshold_mg: float,
) -> list[CaffeineForecastPoint]:
    points: list[CaffeineForecastPoint] = []
    cursor = start
    while cursor <= end:
        remaining = _remaining_caffeine(entries, cursor, half_life_hours)
        points.append(
            CaffeineForecastPoint(
                at=cursor,
                remaining_caffeine_mg=round(remaining, 1),
                stage=_sleep_stage(remaining, safe_threshold_mg),
            )
        )
        cursor += timedelta(hours=2)
    return points


def _build_summary(
    *,
    sleep_at: datetime,
    projected_sleep_mg: float,
    readiness: SleepReadiness,
    recommended_sleep_time: datetime | None,
) -> str:
    sleep_text = sleep_at.strftime("%H:%M")
    projected_text = f"{projected_sleep_mg:.0f}mg"

    if readiness == "sleep-friendly":
        return f"按 {sleep_text} 入睡计算，届时预计剩余 {projected_text} 咖啡因，影响相对可控。"

    if recommended_sleep_time is None:
        return f"按 {sleep_text} 入睡计算，届时预计仍有 {projected_text} 咖啡因残留，今晚更可能拖慢入睡。"

    return (
        f"按 {sleep_text} 入睡计算，届时预计仍有 {projected_text} 咖啡因残留。"
        f"更接近适合入睡的时间点大约在 {recommended_sleep_time.strftime('%H:%M')}。"
    )


def _build_sleep_impact(
    *,
    readiness: SleepReadiness,
    safe_threshold_mg: float,
    projected_sleep_mg: float,
) -> str:
    if readiness == "sleep-friendly":
        return f"睡前残留已压到约 {projected_sleep_mg:.0f}mg，低于参考阈值 {safe_threshold_mg:.0f}mg。"
    if readiness == "watch":
        return f"睡前残留约 {projected_sleep_mg:.0f}mg，仍高于参考阈值，可能让你更浅眠或更难放松。"
    return f"睡前残留约 {projected_sleep_mg:.0f}mg，明显高于参考阈值，较容易拉长入睡潜伏期。"
