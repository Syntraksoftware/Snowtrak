"""Notification API tests."""

from app.core.jwt import create_access_token
from app.core.supabase import supabase_client
from app.services import notification_sender as sender_module


def _auth_headers(user):
    token = create_access_token({"sub": user.id, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


class TestDeviceTokenEndpoint:
    def test_register_device_token(self, client, test_user, monkeypatch):
        token = "fcm-token-" + ("x" * 32)

        def fake_upsert_device_token(**kwargs):
            return {
                "user_id": kwargs["user_id"],
                "token": kwargs["token"],
                "platform": kwargs["platform"],
                "device_id": kwargs["device_id"],
                "app_version": kwargs["app_version"],
                "locale": kwargs["locale"],
                "timezone": kwargs["timezone"],
                "is_active": True,
            }

        monkeypatch.setattr(supabase_client, "upsert_device_token", fake_upsert_device_token)

        response = client.post(
            "/api/v1/notifications/device-tokens",
            headers=_auth_headers(test_user),
            json={
                "token": token,
                "platform": "ios",
                "device_id": "ios-simulator",
                "app_version": "1.0.0",
                "locale": "en-HK",
                "timezone": "Asia/Hong_Kong",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["user_id"] == test_user.id
        assert data["token"] == token
        assert data["platform"] == "ios"
        assert data["is_active"] is True

    def test_register_device_token_requires_auth(self, client):
        response = client.post(
            "/api/v1/notifications/device-tokens",
            json={"token": "fcm-token-" + ("x" * 32), "platform": "ios"},
        )

        assert response.status_code == 401

    def test_unregister_device_token(self, client, test_user, monkeypatch):
        calls = []

        def fake_deactivate_device_token(**kwargs):
            calls.append(kwargs)
            return True

        monkeypatch.setattr(
            supabase_client, "deactivate_device_token", fake_deactivate_device_token
        )

        token = "fcm-token-" + ("x" * 32)
        response = client.request(
            "DELETE",
            "/api/v1/notifications/device-tokens",
            headers=_auth_headers(test_user),
            json={"token": token},
        )

        assert response.status_code == 204
        assert calls == [{"user_id": test_user.id, "token": token}]


class TestSendNotificationEndpoint:
    def test_send_notification_self_test(self, client, test_user, monkeypatch):
        def fake_send_to_user(user_id, payload):
            assert user_id == test_user.id
            assert payload.title == "Test"
            return sender_module.NotificationSendResult(requested=1, successful=1, failed=0)

        monkeypatch.setattr(sender_module.notification_sender, "send_to_user", fake_send_to_user)

        response = client.post(
            "/api/v1/notifications/send",
            headers=_auth_headers(test_user),
            json={"user_id": test_user.id, "title": "Test", "body": "Hello"},
        )

        assert response.status_code == 200
        assert response.json()["successful"] == 1

    def test_send_notification_rejects_other_user(self, client, test_user):
        response = client.post(
            "/api/v1/notifications/send",
            headers=_auth_headers(test_user),
            json={"user_id": "another-user-id", "title": "Test", "body": "Hello"},
        )

        assert response.status_code == 403
