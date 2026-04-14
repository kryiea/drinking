from datetime import date
from typing import List

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_repository, get_user_id
from app.domain.models import RecommendationDecision
from app.domain.repository import AppRepository
from app.services.recommendations import build_recommendations

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


@router.get("", response_model=List[RecommendationDecision])
def get_recommendations(
    day: date = Query(alias="date"),
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> List[RecommendationDecision]:
    aggregate = repository.get_daily_aggregate(user_id, day)
    goals = repository.get_goals(user_id)
    profile = repository.get_profile(user_id)
    toggles = repository.rule_toggles
    return build_recommendations(
        aggregate=aggregate,
        goals=goals,
        profile=profile,
        caffeine_warning_ratio=toggles.caffeine_warning_ratio,
        sugar_warning_ratio=toggles.sugar_warning_ratio,
        late_caffeine_hour=toggles.late_caffeine_hour,
    )
