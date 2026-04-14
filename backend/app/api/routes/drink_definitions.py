from typing import List, Optional

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_repository
from app.domain.models import BrewCalculatorRequest, BrewCalculatorResult, DrinkDefinition
from app.domain.repository import AppRepository

router = APIRouter(prefix="/drink-definitions", tags=["drink-definitions"])


@router.get("", response_model=List[DrinkDefinition])
def list_drink_definitions(
    q: str = Query(default=""),
    category: Optional[str] = Query(default=None),
    brand: Optional[str] = Query(default=None),
    method: Optional[str] = Query(default=None),
    repository: AppRepository = Depends(get_repository),
) -> List[DrinkDefinition]:
    return repository.search_drink_definitions(q, category, brand, method)


@router.post("/brew-calculator", response_model=BrewCalculatorResult)
def calculate_brew(
    payload: BrewCalculatorRequest,
    repository: AppRepository = Depends(get_repository),
) -> BrewCalculatorResult:
    return repository.estimate_brew(payload)
