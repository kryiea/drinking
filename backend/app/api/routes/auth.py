from fastapi import APIRouter, Depends

from app.api.deps import get_repository
from app.domain.models import AppleAuthRequest, SessionResponse
from app.domain.repository import AppRepository

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/apple", response_model=SessionResponse)
def exchange_apple_token(
    payload: AppleAuthRequest,
    repository: AppRepository = Depends(get_repository),
) -> SessionResponse:
    return repository.exchange_apple_token(payload)
