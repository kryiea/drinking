from datetime import datetime

import httpx
import pytest
from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import create_app


@pytest.fixture
def client(tmp_path):
    database_url = f"sqlite:///{tmp_path / 'yinzhi-test.db'}"
    app = create_app(database_url=database_url)
    with TestClient(app) as test_client:
        yield test_client


def test_catalog_search_returns_seed_data(client: TestClient) -> None:
    response = client.get("/v1/drink-definitions", params={"q": "奶"})
    assert response.status_code == 200
    payload = response.json()
    assert any(item["id"] == "jasmine-milk-tea" for item in payload)
    assert any(item["brand"] == "MANNER" for item in client.get("/v1/drink-definitions", params={"brand": "MANNER"}).json())


def test_brew_calculator_returns_scaled_recipe(client: TestClient) -> None:
    response = client.post(
        "/v1/drink-definitions/brew-calculator",
        json={
            "drink_definition_id": "pour-over-yirgacheffe",
            "target_volume_ml": 390,
            "strength": "bold",
        },
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["method"] == "hand-brew"
    assert payload["coffee_g"] > 18
    assert "390ml" in payload["summary"]


def test_log_insights_and_recommendations_round_trip(client: TestClient) -> None:
    create_response = client.post(
        "/v1/drink-logs",
        json={
            "drink_definition_id": "energy-shot",
            "consumed_at": datetime(2026, 4, 13, 14, 30).isoformat(),
            "ratio": 1.0,
            "source": "catalog",
        },
        headers={"x-user-id": "demo-user"},
    )
    assert create_response.status_code == 201

    insights = client.get(
        "/v1/daily-insights",
        params={"date": "2026-04-13"},
        headers={"x-user-id": "demo-user"},
    )
    assert insights.status_code == 200
    insights_payload = insights.json()
    assert insights_payload["entries_count"] >= 1
    assert insights_payload["totals"]["caffeine_mg"] >= 180

    recommendations = client.get(
        "/v1/recommendations",
        params={"date": "2026-04-13"},
        headers={"x-user-id": "demo-user"},
    )
    assert recommendations.status_code == 200
    cards = recommendations.json()
    assert cards
    assert {"rule_id", "trigger", "inputs", "threshold_comparison", "action", "risk"} <= set(
        cards[0]["explanation"].keys()
    )


def test_caffeine_forecast_and_ai_brief_return_structured_insight(client: TestClient) -> None:
    now = datetime.now().replace(microsecond=0)
    response = client.post(
        "/v1/drink-logs",
        json={
            "drink_definition_id": "latte-oat",
            "consumed_at": now.isoformat(),
            "ratio": 1.0,
            "source": "catalog",
        },
        headers={"x-user-id": "demo-user"},
    )
    assert response.status_code == 201

    forecast = client.get(
        "/v1/daily-insights/caffeine-forecast",
        headers={"x-user-id": "demo-user"},
    )
    assert forecast.status_code == 200
    forecast_payload = forecast.json()
    assert forecast_payload["current_estimate_mg"] > 0
    assert forecast_payload["sleep_readiness"] in {"sleep-friendly", "watch", "likely-disruptive"}
    assert len(forecast_payload["timeline"]) >= 3

    ai_brief = client.get(
        "/v1/daily-insights/ai-brief",
        headers={"x-user-id": "demo-user"},
    )
    assert ai_brief.status_code == 200
    ai_payload = ai_brief.json()
    assert ai_payload["mode"] == "fallback"
    assert ai_payload["headline"]
    assert ai_payload["next_actions"]


def test_auth_exchange_returns_session(client: TestClient) -> None:
    response = client.post(
        "/v1/auth/apple",
        json={"identity_token": "identity-token-for-demo-user", "device_name": "iPhone 17 Pro"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["access_token"].startswith("demo-session-")
    assert payload["user_id"].startswith("apple-")


def test_admin_rules_can_be_updated(client: TestClient) -> None:
    response = client.put(
        "/v1/admin/rules",
        json={
            "caffeine_warning_ratio": 0.7,
            "sugar_warning_ratio": 0.85,
            "late_caffeine_hour": 14,
            "enabled_rules": ["caffeine-warning", "late-caffeine"],
        },
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["late_caffeine_hour"] == 14

    snapshot = client.get("/v1/admin/snapshot")
    assert snapshot.status_code == 200
    assert snapshot.json()["pending_feedback"] >= 1
    assert snapshot.json()["brand_count"] >= 3


def test_support_endpoints_expose_llm_and_feedback_workflow(client: TestClient) -> None:
    support_snapshot = client.get("/v1/admin/support")
    assert support_snapshot.status_code == 200
    support_payload = support_snapshot.json()
    assert support_payload["admin"]["drink_count"] >= 5
    assert support_payload["llm"]["configured"] is False

    llm_preview = client.post("/v1/admin/llm-preview", json={"prompt": "给一条 UX 建议"})
    assert llm_preview.status_code == 200
    assert llm_preview.json()["mode"] == "fallback"

    feedback = client.post("/v1/admin/feedback/feedback-1/review")
    assert feedback.status_code == 200
    assert feedback.json()["status"] == "reviewed"

    support_page = client.get("/support")
    assert support_page.status_code == 200
    assert "Support Console" in support_page.text


def test_llm_preview_surfaces_provider_error_without_500(client: TestClient, monkeypatch: pytest.MonkeyPatch) -> None:
    async def fake_post(self, url, headers=None, json=None):  # pragma: no cover - exercised through route
        request = httpx.Request("POST", url, headers=headers, json=json)
        response = httpx.Response(
            401,
            request=request,
            json={"error": {"message": "Invalid Authentication"}},
        )
        raise httpx.HTTPStatusError("upstream auth failed", request=request, response=response)

    monkeypatch.setattr(settings, "llm_base_url", "https://api.moonshot.cn/v1")
    monkeypatch.setattr(settings, "llm_api_key", "test-key")
    monkeypatch.setattr(settings, "llm_model", "kimi-k2-0905-preview")
    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    llm_preview = client.post("/v1/admin/llm-preview", json={"prompt": "给一条 UX 建议"})
    assert llm_preview.status_code == 200
    assert llm_preview.json()["mode"] == "fallback"
    assert "Invalid Authentication" in llm_preview.json()["output"]


def test_data_persists_across_app_restarts(tmp_path) -> None:
    database_url = f"sqlite:///{tmp_path / 'persistent.db'}"

    first_app = create_app(database_url=database_url)
    with TestClient(first_app) as first_client:
        first_client.post(
            "/v1/drink-logs",
            json={
                "drink_definition_id": "latte-oat",
                "consumed_at": datetime(2026, 4, 14, 9, 15).isoformat(),
                "ratio": 1.0,
                "source": "catalog",
            },
            headers={"x-user-id": "persistent-user"},
        )

    second_app = create_app(database_url=database_url)
    with TestClient(second_app) as second_client:
        response = second_client.get("/v1/drink-logs", headers={"x-user-id": "persistent-user"})
        assert response.status_code == 200
        payload = response.json()
        assert len(payload) == 1
        assert payload[0]["drink_name"] == "燕麦拿铁"
