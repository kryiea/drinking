from fastapi import APIRouter, Depends

from app.api.deps import get_repository, get_user_id
from app.domain.models import HealthGoals
from app.domain.repository import AppRepository

router = APIRouter(prefix="/goals", tags=["goals"])


@router.get("", response_model=HealthGoals)
def get_goals(
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> HealthGoals:
    return repository.get_goals(user_id)


@router.put("", response_model=HealthGoals)
def update_goals(
    payload: HealthGoals,
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> HealthGoals:
    return repository.save_goals(user_id, payload)
