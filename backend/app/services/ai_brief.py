from __future__ import annotations

from datetime import datetime

from app.domain.models import CaffeineForecast, DailyAIBrief, DailyAggregate, HealthGoals, RecommendationDecision, UserProfile
from app.services.llm import OpenAICompatibleLLMService


async def build_daily_ai_brief(
    *,
    aggregate: DailyAggregate,
    goals: HealthGoals,
    profile: UserProfile,
    forecast: CaffeineForecast,
    recommendations: list[RecommendationDecision],
    llm_service: OpenAICompatibleLLMService | None = None,
) -> DailyAIBrief:
    fallback = _build_fallback_brief(
        aggregate=aggregate,
        goals=goals,
        profile=profile,
        forecast=forecast,
        recommendations=recommendations,
    )

    service = llm_service or OpenAICompatibleLLMService()
    mode, output = await service.generate_text(
        system_prompt=(
            "你是饮知 app 内的 AI 解读助手。请用简洁、可信、可执行的中文回答，"
            "不夸大、不做医疗诊断，用 2 到 3 句话总结今天的饮品节奏与睡眠影响。"
        ),
        prompt=_build_llm_prompt(
            aggregate=aggregate,
            goals=goals,
            profile=profile,
            forecast=forecast,
            recommendations=recommendations,
        ),
        temperature=0.4,
    )

    if mode == "live":
        fallback.mode = "live"
        fallback.narrative = output

    return fallback


def _build_fallback_brief(
    *,
    aggregate: DailyAggregate,
    goals: HealthGoals,
    profile: UserProfile,
    forecast: CaffeineForecast,
    recommendations: list[RecommendationDecision],
) -> DailyAIBrief:
    headline = recommendations[0].title if recommendations else "今天的饮品节奏相对平稳"
    next_actions = _build_actions(aggregate=aggregate, goals=goals, forecast=forecast)
    return DailyAIBrief(
        mode="fallback",
        generated_at=datetime.now(),
        headline=headline,
        narrative=(
            f"截至目前你今天一共记录了 {aggregate.entries_count} 杯饮品，"
            f"咖啡因 {aggregate.totals.caffeine_mg:.0f}mg、糖分 {aggregate.totals.sugar_g:.0f}g。"
            f"按 {profile.sleep_time.strftime('%H:%M')} 入睡估算，{forecast.summary}"
        ),
        next_actions=next_actions,
        sleep_note=forecast.sleep_impact,
    )


def _build_actions(
    *,
    aggregate: DailyAggregate,
    goals: HealthGoals,
    forecast: CaffeineForecast,
) -> list[str]:
    actions: list[str] = []

    if forecast.sleep_readiness != "sleep-friendly":
        actions.append("今晚后续尽量只喝无咖啡因饮品，把提神需求换成走动或补水。")
    if aggregate.totals.sugar_g >= goals.sugar_limit_g * 0.8:
        actions.append("下一杯优先无糖或半糖版本，先把液体糖叠加停下来。")
    if aggregate.totals.hydration_ml < goals.hydration_goal_ml * 0.75:
        actions.append("补一杯白水、气泡水或无糖茶，把补水目标往前追一点。")

    if not actions:
        actions.append("保持当前节奏，继续用品牌化记录观察后半天的变化。")

    return actions[:3]


def _build_llm_prompt(
    *,
    aggregate: DailyAggregate,
    goals: HealthGoals,
    profile: UserProfile,
    forecast: CaffeineForecast,
    recommendations: list[RecommendationDecision],
) -> str:
    recommendation_lines = "\n".join(
        f"- {item.title}: {item.explanation.action}" for item in recommendations[:3]
    ) or "- 当前没有额外风险建议"

    return (
        "请结合以下数据，给 app 用户一段更自然但仍然谨慎的今日 AI 解读。\n"
        f"用户目标: 咖啡因上限 {goals.caffeine_limit_mg:.0f}mg，糖分上限 {goals.sugar_limit_g:.0f}g，"
        f"补水目标 {goals.hydration_goal_ml:.0f}ml。\n"
        f"用户档案: 常规睡眠时间 {profile.sleep_time.strftime('%H:%M')}，"
        f"咖啡因敏感 {'是' if profile.caffeine_sensitive else '否'}。\n"
        f"今日累计: {aggregate.entries_count} 杯，咖啡因 {aggregate.totals.caffeine_mg:.0f}mg，"
        f"糖分 {aggregate.totals.sugar_g:.0f}g，补水 {aggregate.totals.hydration_ml:.0f}ml。\n"
        f"睡眠分析: {forecast.summary} {forecast.sleep_impact}\n"
        f"建议候选:\n{recommendation_lines}\n"
        "输出要求: 2 到 3 句话，不要吓人，不要做诊断，要明确给出今晚更适合怎么喝。"
    )
