"""Device token database operations."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class DeviceTokenOperations(SupabaseBase):
    """
    Operations for the device_tokens table.

    Stores Firebase Cloud Messaging registration tokens per user/device. For iOS,
    Firebase maps the FCM token to APNs after the app is configured with APNs.
    """

    def upsert_device_token(
        self,
        *,
        user_id: str,
        token: str,
        platform: str,
        device_id: str | None = None,
        app_version: str | None = None,
        locale: str | None = None,
        timezone: str | None = None,
    ) -> dict[str, Any] | None:
        """Create or refresh a device token row."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping device token upsert.")
            return None

        client = self._client
        if client is None:
            return None

        now = datetime.now(UTC).isoformat()
        payload = {
            "user_id": user_id,
            "token": token,
            "platform": platform,
            "device_id": device_id,
            "app_version": app_version,
            "locale": locale,
            "timezone": timezone,
            "is_active": True,
            "last_seen_at": now,
        }

        try:
            resp = client.table("device_tokens").upsert(payload, on_conflict="token").execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            if isinstance(data, dict):
                return data
            return None
        except Exception as exc:
            logger.exception("Supabase device token upsert failed: %s", exc)
            return None

    def deactivate_device_token(self, *, user_id: str, token: str) -> bool:
        """Mark a user's device token inactive."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping device token deactivate.")
            return False

        client = self._client
        if client is None:
            return False

        try:
            client.table("device_tokens").update({"is_active": False}).eq("user_id", user_id).eq(
                "token", token
            ).execute()
            return True
        except Exception as exc:
            logger.exception("Supabase device token deactivate failed: %s", exc)
            return False

    def get_active_device_tokens_for_user(self, user_id: str) -> list[dict[str, Any]]:
        """Return all active device token rows for a user."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping device token select.")
            return []

        client = self._client
        if client is None:
            return []

        try:
            resp = (
                client.table("device_tokens")
                .select("*")
                .eq("user_id", user_id)
                .eq("is_active", True)
                .execute()
            )
            data = getattr(resp, "data", None)
            return data if isinstance(data, list) else []
        except Exception as exc:
            logger.exception("Supabase device token select failed: %s", exc)
            return []

    def deactivate_device_tokens(self, tokens: list[str]) -> bool:
        """Mark a batch of tokens inactive."""
        if not tokens:
            return True
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping device token batch deactivate.")
            return False

        client = self._client
        if client is None:
            return False

        try:
            client.table("device_tokens").update({"is_active": False}).in_("token", tokens).execute()
            return True
        except Exception as exc:
            logger.exception("Supabase device token batch deactivate failed: %s", exc)
            return False
