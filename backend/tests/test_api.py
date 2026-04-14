from datetime import datetime

import pytest
from fastapi.testclient import TestClient

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
