from __future__ import annotations

from typing import Any, Optional

import httpx

from app.core.config import settings
from app.domain.models import LLMPreviewRequest, LLMPreviewResponse, LLMProviderStatus


class OpenAICompatibleLLMService:
    def status(self) -> LLMProviderStatus:
        configured = bool(settings.llm_base_url and settings.llm_api_key and settings.llm_model)
        return LLMProviderStatus(
            configured=configured,
            provider=settings.llm_provider,
            base_url=settings.llm_base_url,
            model=settings.llm_model,
            mode="ready" if configured else "not-configured",
        )

    async def preview(self, payload: LLMPreviewRequest) -> LLMPreviewResponse:
        status = self.status()
        mode, output = await self.generate_text(
            system_prompt=payload.system_prompt or "",
            prompt=payload.prompt,
            temperature=payload.temperature,
        )

        return LLMPreviewResponse(
            configured=status.configured,
            provider=settings.llm_provider,
            model=settings.llm_model,
            mode=mode,
            output=output,
        )

    async def generate_text(
        self,
        *,
        system_prompt: str,
        prompt: str,
        temperature: float | None = None,
    ) -> tuple[str, str]:
        status = self.status()
        if status.configured is False:
            return (
                "fallback",
                (
                    "LLM API 还没有配置完成，当前返回的是本地 fallback 结果。"
                    "后续填入 `YINZHI_LLM_BASE_URL`、`YINZHI_LLM_API_KEY` 和 `YINZHI_LLM_MODEL` 后，"
                    "support 平台就可以直接联调 OpenAI 兼容接口。"
                ),
            )

        request_body: dict[str, Any] = {
            "model": settings.llm_model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt},
            ],
        }
        if temperature is not None:
            request_body["temperature"] = temperature

        try:
            async with httpx.AsyncClient(timeout=settings.llm_timeout_seconds) as client:
                response = await client.post(
                    self._chat_completions_url(settings.llm_base_url),
                    headers={
                        "Authorization": f"Bearer {settings.llm_api_key}",
                        "Content-Type": "application/json",
                    },
                    json=request_body,
                )
                response.raise_for_status()
                body = response.json()
        except httpx.HTTPStatusError as exc:
            return "fallback", self._format_provider_error(exc.response)
        except httpx.HTTPError as exc:
            return (
                "fallback",
                f"LLM 上游暂时不可用：{exc.__class__.__name__}。请检查 base URL、网络代理或服务商状态。",
            )

        return "live", self._extract_output(body)

    def _chat_completions_url(self, base_url: Optional[str]) -> str:
        base = (base_url or "").rstrip("/")
        if base.endswith("/chat/completions"):
            return base
        return f"{base}/chat/completions"

    def _extract_output(self, body: dict[str, Any]) -> str:
        choices = body.get("choices")
        if isinstance(choices, list) and choices:
            message = choices[0].get("message", {})
            content = message.get("content")
            if isinstance(content, str) and content.strip():
                return content.strip()

        output = body.get("output_text")
        if isinstance(output, str) and output.strip():
            return output.strip()

        return "LLM 已响应，但当前返回结构未匹配到可展示文本。"

    def _format_provider_error(self, response: httpx.Response) -> str:
        message = f"LLM 上游返回错误：HTTP {response.status_code}"
        try:
            body = response.json()
        except ValueError:
            body = None

        if isinstance(body, dict):
            error = body.get("error")
            if isinstance(error, dict):
                provider_message = error.get("message")
                if isinstance(provider_message, str) and provider_message.strip():
                    return f"{message} · {provider_message.strip()}"
            detail = body.get("message")
            if isinstance(detail, str) and detail.strip():
                return f"{message} · {detail.strip()}"

        text = response.text.strip()
        if text:
            return f"{message} · {text[:300]}"
        return message
