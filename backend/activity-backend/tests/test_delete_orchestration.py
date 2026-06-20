from unittest.mock import AsyncMock

import pytest
from fastapi import status

from middleware.auth import get_current_user
from routes import activities_management_routes
from services.activity_deletion_service import ActivityDeletionService
from services.map_backend_client import MapBackendClient


@pytest.fixture
def orchestration_client(app, stub_client, monkeypatch):
    map_delete = AsyncMock()
    monkeypatch.setattr(
        MapBackendClient,
        "delete_map_activity",
        map_delete,
    )
    monkeypatch.setattr(
        activities_management_routes,
        "get_activity_client",
        lambda: stub_client,
    )

    stub_client._activity["map_activity_id"] = "map-activity-99"
    app.dependency_overrides[get_current_user] = lambda: "user-1"

    from fastapi.testclient import TestClient

    with TestClient(app) as client:
        yield client, map_delete, stub_client

    app.dependency_overrides.clear()


class TestDeleteOrchestration:
    def test_delete_calls_map_backend_before_public_row(self, orchestration_client):
        client, map_delete, stub_client = orchestration_client

        response = client.delete("/api/v1/activities/activity-1")

        assert response.status_code == status.HTTP_200_OK
        map_delete.assert_awaited_once_with("map-activity-99")

    def test_delete_aborts_when_map_backend_fails(self, orchestration_client):
        client, map_delete, stub_client = orchestration_client
        map_delete.side_effect = RuntimeError("map-backend down")

        response = client.delete("/api/v1/activities/activity-1")

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        assert stub_client.get_activity_by_id("activity-1") is not None
