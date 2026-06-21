"""Firebase Cloud Messaging notification sender service."""

from __future__ import annotations

import logging
from typing import Any

from app.core.config import settings
from app.core.supabase import supabase_client
from app.schemas.notifications import NotificationPayload, NotificationSendResult

logger = logging.getLogger(__name__)


class NotificationConfigurationError(RuntimeError):
    """Raised when Firebase notification sending is not configured."""


class NotificationSenderService:
    """Sends push notifications through Firebase Cloud Messaging."""

    def __init__(self) -> None:
        self._initialized = False

    def _ensure_firebase_initialized(self) -> None:
        if self._initialized:
            return

        try:
            import firebase_admin
            from firebase_admin import credentials
        except ImportError as exc:
            raise NotificationConfigurationError(
                "firebase-admin is not installed. Install requirements.txt dependencies."
            ) from exc

        if firebase_admin._apps:
            self._initialized = True
            return

        credentials_path = settings.firebase_credentials_path
        if not credentials_path:
            raise NotificationConfigurationError(
                "FIREBASE_CREDENTIALS_PATH is not configured for Firebase Admin."
            )

        options: dict[str, Any] = {}
        if settings.firebase_project_id:
            options["projectId"] = settings.firebase_project_id

        firebase_admin.initialize_app(credentials.Certificate(credentials_path), options)
        self._initialized = True

    def send_to_user(self, user_id: str, payload: NotificationPayload) -> NotificationSendResult:
        """Send a notification to every active device registered for a user."""
        token_rows = supabase_client.get_active_device_tokens_for_user(user_id)
        tokens = [row["token"] for row in token_rows if row.get("token")]
        if not tokens:
            return NotificationSendResult(requested=0, successful=0, failed=0)

        return self.send_to_tokens(tokens, payload)

    def send_to_tokens(
        self, tokens: list[str], payload: NotificationPayload
    ) -> NotificationSendResult:
        """Send a notification to explicit FCM registration tokens."""
        clean_tokens = sorted({token.strip() for token in tokens if token and token.strip()})
        if not clean_tokens:
            return NotificationSendResult(requested=0, successful=0, failed=0)

        self._ensure_firebase_initialized()

        from firebase_admin import messaging

        message = messaging.MulticastMessage(
            tokens=clean_tokens,
            notification=messaging.Notification(
                title=payload.title,
                body=payload.body,
                image=payload.image_url,
            ),
            data=payload.data,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(sound=payload.sound),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound=payload.sound, badge=payload.badge)
                )
            ),
        )

        response = messaging.send_each_for_multicast(message)
        deactivated_tokens: list[str] = []
        errors: list[str] = []

        for index, item in enumerate(response.responses):
            if item.success:
                continue
            token = clean_tokens[index]
            error = item.exception
            error_text = str(error) if error else "Unknown Firebase send error"
            errors.append(f"{token}: {error_text}")

            code = getattr(error, "code", None)
            if code in {"registration-token-not-registered", "invalid-argument"}:
                deactivated_tokens.append(token)

        if deactivated_tokens:
            supabase_client.deactivate_device_tokens(deactivated_tokens)

        if errors:
            logger.warning("Notification send completed with failures: %s", errors)

        return NotificationSendResult(
            requested=len(clean_tokens),
            successful=response.success_count,
            failed=response.failure_count,
            deactivated_tokens=deactivated_tokens,
            errors=errors,
        )


notification_sender = NotificationSenderService()
