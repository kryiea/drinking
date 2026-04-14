from typing import List, Optional

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_repository
from app.domain.models import DrinkDefinition
from app.domain.repository import AppRepository

router = APIRouter(prefix="/drink-definitions", tags=["drink-definitions"])


@router.get("", response_model=List[DrinkDefinition])
def list_drink_definitions(
    q: str = Query(default=""),
    category: Optional[str] = Query(default=None),
    repository: AppRepository = Depends(get_repository),
) -> List[DrinkDefinition]:
    return repository.search_drink_definitions(q, category)
