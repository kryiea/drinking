from typing import List

from fastapi import APIRouter, Depends

from app.api.deps import get_repository
from app.domain.models import AdminSnapshot, FeedbackItem, RuleToggles
from app.domain.repository import AppRepository

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/snapshot", response_model=AdminSnapshot)
def get_admin_snapshot(repository: AppRepository = Depends(get_repository)) -> AdminSnapshot:
    return repository.get_admin_snapshot()


@router.get("/feedback", response_model=List[FeedbackItem])
def list_feedback(repository: AppRepository = Depends(get_repository)) -> List[FeedbackItem]:
    return repository.list_feedback()


@router.get("/rules", response_model=RuleToggles)
def get_rule_toggles(repository: AppRepository = Depends(get_repository)) -> RuleToggles:
    return repository.rule_toggles


@router.put("/rules", response_model=RuleToggles)
def update_rule_toggles(
    payload: RuleToggles,
    repository: AppRepository = Depends(get_repository),
) -> RuleToggles:
    return repository.update_rule_toggles(payload)
