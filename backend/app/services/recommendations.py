from datetime import date
from typing import List

from app.domain.models import DailyAggregate, HealthGoals, RecommendationDecision, RecommendationExplanation, UserProfile


def build_recommendations(
    aggregate: DailyAggregate,
    goals: HealthGoals,
    profile: UserProfile,
    caffeine_warning_ratio: float,
    sugar_warning_ratio: float,
    late_caffeine_hour: int,
) -> List[RecommendationDecision]:
    decisions: List[RecommendationDecision] = []

    caffeine_ratio = aggregate.totals.caffeine_mg / goals.caffeine_limit_mg if goals.caffeine_limit_mg else 0
    sugar_ratio = aggregate.totals.sugar_g / goals.sugar_limit_g if goals.sugar_limit_g else 0

    if caffeine_ratio >= caffeine_warning_ratio:
        severity = "critical" if caffeine_ratio >= 1 else "warning"
        decisions.append(
            RecommendationDecision(
                severity=severity,
                title="今日咖啡因偏高",
                summary="建议后续改喝低咖啡因或无咖啡因饮品，避免影响晚间休息。",
                explanation=RecommendationExplanation(
                    rule_id="caffeine-warning",
                    trigger="今日咖啡因摄入接近或超过上限",
                    inputs={
                        "daily_caffeine_mg": round(aggregate.totals.caffeine_mg, 2),
                        "goal_caffeine_mg": round(goals.caffeine_limit_mg, 2),
                        "user_weight_kg": round(profile.weight_kg, 2),
                    },
                    threshold_comparison=f"{aggregate.totals.caffeine_mg:.0f}mg / {goals.caffeine_limit_mg:.0f}mg",
                    action="后续优先选择气泡水、低因拿铁或无糖茶饮；晚间避免再摄入含咖啡因饮品。",
                    risk="高咖啡因可能增加心悸、焦虑和入睡延迟风险。",
                ),
            )
        )

    if sugar_ratio >= sugar_warning_ratio:
        severity = "critical" if sugar_ratio >= 1 else "warning"
        decisions.append(
            RecommendationDecision(
                severity=severity,
                title="今日游离糖摄入偏高",
                summary="下一杯建议选择半糖或无糖版本，优先减少液体糖来源。",
                explanation=RecommendationExplanation(
                    rule_id="sugar-warning",
                    trigger="今日糖分摄入接近或超过目标",
                    inputs={
                        "daily_sugar_g": round(aggregate.totals.sugar_g, 2),
                        "goal_sugar_g": round(goals.sugar_limit_g, 2),
                        "blood_sugar_watch": "true" if profile.blood_sugar_watch else "false",
                    },
                    threshold_comparison=f"{aggregate.totals.sugar_g:.0f}g / {goals.sugar_limit_g:.0f}g",
                    action="优先选择半糖、无糖和高纤替代饮品，减少奶茶和功能饮料频次。",
                    risk="连续高糖摄入会推高热量负担，并增加代谢控制压力。",
                ),
            )
        )

    late_caffeine_entries = [
        item for item in aggregate.category_breakdown if item.category == "咖啡"
    ]
    if late_caffeine_entries and profile.sleep_time.hour <= 24 and late_caffeine_hour >= 0:
        # The current bootstrap does not keep per-entry times in the aggregate, so we provide a stable guidance card
        decisions.append(
            RecommendationDecision(
                severity="info",
                title="下午咖啡因窗口提醒",
                summary=f"若你通常在 {profile.sleep_time.strftime('%H:%M')} 睡觉，建议 {late_caffeine_hour}:00 后避免再喝高咖啡因饮品。",
                explanation=RecommendationExplanation(
                    rule_id="late-caffeine",
                    trigger="今日存在咖啡类摄入，需要结合睡眠时间给出时间窗口建议",
                    inputs={
                        "sleep_hour": profile.sleep_time.hour,
                        "late_caffeine_hour": late_caffeine_hour,
                        "date": date.isoformat(aggregate.date),
                    },
                    threshold_comparison=f"睡眠时间 {profile.sleep_time.strftime('%H:%M')} -> 建议截止 {late_caffeine_hour}:00",
                    action="把提神需求前移到午后早段，晚些时候改喝无糖气泡水或热茶。",
                    risk="过晚摄入咖啡因会拉长入睡潜伏期并降低睡眠质量。",
                ),
            )
        )

    if not decisions:
        decisions.append(
            RecommendationDecision(
                severity="info",
                title="今日节奏稳定",
                summary="目前摄入仍在目标范围内，可以继续保持节制和补水。",
                explanation=RecommendationExplanation(
                    rule_id="within-range",
                    trigger="当前摄入未触发风险阈值",
                    inputs={
                        "daily_caffeine_mg": round(aggregate.totals.caffeine_mg, 2),
                        "daily_sugar_g": round(aggregate.totals.sugar_g, 2),
                        "hydration_ml": round(aggregate.totals.hydration_ml, 2),
                    },
                    threshold_comparison="所有关键指标均低于预警线",
                    action="延续当前饮品选择，并优先补足饮水目标。",
                    risk="若晚上仍继续摄入高糖或高咖啡因饮品，风险会迅速上升。",
                ),
            )
        )

    return decisions
