"""Base Supabase client with connection management."""

from __future__ import annotations

import logging

from app.core.config import settings
from supabase import Client, create_client

logger = logging.getLogger(__name__)


class SupabaseBase:
    """
    Base wrapper around Supabase Python SDK.

    Handles connection initialization and configuration checking.
    """

    def __init__(self, url: str | None = None, service_key: str | None = None) -> None:
        # Access settings attributes defensively to satisfy type checkers
        cfg_url = getattr(settings, "supabase_url", None)
        cfg_key = getattr(settings, "supabase_service_role_key", None)
        self._url = url or cfg_url
        self._key = service_key or cfg_key
        self._client: Client | None = None

        if self._url and self._key:
            try:
                self._client = create_client(self._url, self._key)
            except Exception as exc:
                logger.exception("Failed to initialize Supabase client: %s", exc)
                self._client = None
        else:
            logger.warning("Supabase URL/key not configured; client disabled.")

    def is_configured(self) -> bool:
        """Return True if the client is ready to use."""
        if self._client is None and self._url and self._key:
            # Lazy re-initialization if credentials are now available
            try:
                self._client = create_client(self._url, self._key)
            except Exception as exc:
                logger.exception("Failed to re-init Supabase client: %s", exc)
        return self._client is not None

    @property
    def client(self) -> Client | None:
        """Get the underlying Supabase client."""
        return self._client
