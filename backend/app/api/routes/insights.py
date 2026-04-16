from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_repository, get_user_id
from app.domain.models import CaffeineForecast, DailyAIBrief, DailyAggregate
from app.domain.repository import AppRepository
from app.services.ai_brief import build_daily_ai_brief
from app.services.caffeine import build_caffeine_forecast
from app.services.llm import OpenAICompatibleLLMService
from app.services.recommendations import build_recommendations

router = APIRouter(prefix="/daily-insights", tags=["daily-insights"])
llm_service = OpenAICompatibleLLMService()


@router.get("", response_model=DailyAggregate)
def get_daily_insights(
    day: date = Query(alias="date"),
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> DailyAggregate:
    return repository.get_daily_aggregate(user_id, day)


@router.get("/caffeine-forecast", response_model=CaffeineForecast)
def get_caffeine_forecast(
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> CaffeineForecast:
    profile = repository.get_profile(user_id)
    entries = repository.list_logs(user_id)
    return build_caffeine_forecast(entries, profile)


@router.get("/ai-brief", response_model=DailyAIBrief)
async def get_ai_brief(
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> DailyAIBrief:
    today = date.today()
    aggregate = repository.get_daily_aggregate(user_id, today)
    goals = repository.get_goals(user_id)
    profile = repository.get_profile(user_id)
    entries = repository.list_logs(user_id)
    toggles = repository.rule_toggles
    forecast = build_caffeine_forecast(entries, profile)
    recommendations = build_recommendations(
        aggregate=aggregate,
        goals=goals,
        profile=profile,
        caffeine_warning_ratio=toggles.caffeine_warning_ratio,
        sugar_warning_ratio=toggles.sugar_warning_ratio,
        late_caffeine_hour=toggles.late_caffeine_hour,
    )
    return await build_daily_ai_brief(
        aggregate=aggregate,
        goals=goals,
        profile=profile,
        forecast=forecast,
        recommendations=recommendations,
        llm_service=llm_service,
    )
