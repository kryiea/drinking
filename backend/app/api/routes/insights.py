from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_repository, get_user_id
from app.domain.models import DailyAggregate
from app.domain.repository import AppRepository

router = APIRouter(prefix="/daily-insights", tags=["daily-insights"])


@router.get("", response_model=DailyAggregate)
def get_daily_insights(
    day: date = Query(alias="date"),
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> DailyAggregate:
    return repository.get_daily_aggregate(user_id, day)
