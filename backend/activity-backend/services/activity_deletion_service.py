"""Orchestrated activity deletion across public.activities and map_trail."""

from __future__ import annotations

import logging

import httpx

from services.map_backend_client import MapBackendClient, get_map_backend_client
from services.supabase_client import ActivitySupabaseClient

logger = logging.getLogger(__name__)


class ActivityDeletionService:
    def __init__(
        self,
        activity_client: ActivitySupabaseClient,
        map_client: MapBackendClient | None = None,
    ) -> None:
        self._activity_client = activity_client
        self._map_client = map_client or get_map_backend_client()

    async def delete_activity(self, activity_id: str, user_id: str) -> bool:
        record = self._activity_client.get_activity_by_id(activity_id)
        if not record or str(record.get("user_id")) != user_id:
            return False

        map_activity_id = record.get("map_activity_id")
        if map_activity_id:
            try:
                await self._map_client.delete_map_activity(str(map_activity_id))
            except httpx.HTTPError:
                logger.exception(
                    "map-backend delete failed for map_activity_id=%s; aborting public delete",
                    map_activity_id,
                )
                raise

        return self._activity_client.delete_activity(activity_id, user_id)
