from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status

from app.api.deps import get_repository, get_user_id
from app.domain.models import DrinkLogCreateRequest, DrinkLogEntry, DrinkLogUpdateRequest
from app.domain.repository import AppRepository

router = APIRouter(prefix="/drink-logs", tags=["drink-logs"])


@router.get("", response_model=List[DrinkLogEntry])
def list_drink_logs(
    day: Optional[date] = Query(default=None),
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> List[DrinkLogEntry]:
    return repository.list_logs(user_id, day)


@router.post("", response_model=DrinkLogEntry, status_code=status.HTTP_201_CREATED)
def create_drink_log(
    payload: DrinkLogCreateRequest,
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> DrinkLogEntry:
    return repository.create_log(user_id, payload)


@router.patch("/{entry_id}", response_model=DrinkLogEntry)
def update_drink_log(
    entry_id: str,
    payload: DrinkLogUpdateRequest,
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> DrinkLogEntry:
    try:
        return repository.update_log(user_id, entry_id, payload)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=f"log entry {entry_id} not found") from exc


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_drink_log(
    entry_id: str,
    user_id: str = Depends(get_user_id),
    repository: AppRepository = Depends(get_repository),
) -> Response:
    repository.delete_log(user_id, entry_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
