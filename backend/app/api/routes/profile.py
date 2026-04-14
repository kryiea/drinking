from fastapi import APIRouter, Depends

from app.api.deps import get_repository, get_user_id
from app.domain.models import UserProfile
from app.domain.repository import AppRepository

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserProfile)
def get_profile(
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> UserProfile:
    return repository.get_profile(user_id)


@router.put("", response_model=UserProfile)
def update_profile(
    payload: UserProfile,
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> UserProfile:
    return repository.save_profile(user_id, payload)
