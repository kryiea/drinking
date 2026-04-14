from fastapi import APIRouter, Depends, status

from app.api.deps import get_repository
from app.domain.models import ExportRequest, ExportTask
from app.domain.repository import AppRepository

router = APIRouter(prefix="/exports", tags=["exports"])


@router.post("", response_model=ExportTask, status_code=status.HTTP_202_ACCEPTED)
def create_export(
    payload: ExportRequest,
    repository: AppRepository = Depends(get_repository),
) -> ExportTask:
    return repository.create_export(payload)
