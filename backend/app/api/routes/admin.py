from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_repository
from app.core.config import settings
from app.domain.models import (
    AdminSnapshot,
    FeedbackItem,
    LLMPreviewRequest,
    LLMPreviewResponse,
    LLMProviderStatus,
    RuleToggles,
    ServiceStatus,
    SupportPlatformSnapshot,
)
from app.domain.repository import AppRepository
from app.services.llm import OpenAICompatibleLLMService

router = APIRouter(prefix="/admin", tags=["admin"])
llm_service = OpenAICompatibleLLMService()


@router.get("/snapshot", response_model=AdminSnapshot)
def get_admin_snapshot(repository: AppRepository = Depends(get_repository)) -> AdminSnapshot:
    return repository.get_admin_snapshot()


@router.get("/feedback", response_model=List[FeedbackItem])
def list_feedback(repository: AppRepository = Depends(get_repository)) -> List[FeedbackItem]:
    return repository.list_feedback()


@router.post("/feedback/{feedback_id}/review", response_model=FeedbackItem)
def review_feedback(
    feedback_id: str,
    repository: AppRepository = Depends(get_repository),
) -> FeedbackItem:
    try:
        return repository.mark_feedback_reviewed(feedback_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=f"feedback {feedback_id} not found") from exc


@router.get("/rules", response_model=RuleToggles)
def get_rule_toggles(repository: AppRepository = Depends(get_repository)) -> RuleToggles:
    return repository.rule_toggles


@router.put("/rules", response_model=RuleToggles)
def update_rule_toggles(
    payload: RuleToggles,
    repository: AppRepository = Depends(get_repository),
) -> RuleToggles:
    return repository.update_rule_toggles(payload)


@router.get("/llm-status", response_model=LLMProviderStatus)
def get_llm_status() -> LLMProviderStatus:
    return llm_service.status()


@router.post("/llm-preview", response_model=LLMPreviewResponse)
async def preview_llm(payload: LLMPreviewRequest) -> LLMPreviewResponse:
    return await llm_service.preview(payload)


@router.get("/support", response_model=SupportPlatformSnapshot)
def get_support_snapshot(repository: AppRepository = Depends(get_repository)) -> SupportPlatformSnapshot:
    return SupportPlatformSnapshot(
        admin=repository.get_admin_snapshot(),
        llm=llm_service.status(),
        services=[
            ServiceStatus(
                name="database",
                target=settings.database_url,
                state="ready",
                detail="当前后端已成功启动，数据库连接可用于本地联调。",
            ),
            ServiceStatus(
                name="redis",
                target=settings.redis_url,
                state="configured" if settings.redis_url else "disabled",
                detail="用于后续缓存与任务队列；当前版本仍允许在无 Redis 下开发。",
            ),
            ServiceStatus(
                name="object-storage",
                target=settings.object_storage_endpoint,
                state="configured" if settings.object_storage_endpoint else "disabled",
                detail="导出文件与管理报表后续会落到对象存储兼容层。",
            ),
        ],
        recent_feedback=repository.list_feedback()[:8],
    )
