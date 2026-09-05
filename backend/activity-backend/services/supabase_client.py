"""Supabase client for Activity Backend (skiing activity records)."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any
from uuid import uuid4

from postgrest import CountMethod
from shared.follow_graph import following_ids as _following_ids
from shared.pipeline_enums import ProcessingStatus
from shared.visibility import visible_rows_expression
from supabase import Client, create_client

from config import get_config

logger = logging.getLogger(__name__)

# Global client instance - initialized at startup
_activity_client: ActivitySupabaseClient | None = None


def initialize_activity_client() -> ActivitySupabaseClient:
    """Initialize Supabase client once at application startup."""
    global _activity_client
    config = get_config()
    supabase = create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY)
    _activity_client = ActivitySupabaseClient(supabase)
    logger.info("✅ Activity Supabase client initialized")
    return _activity_client


def get_activity_client() -> ActivitySupabaseClient:
    """Get initialized Supabase client. Raises if not initialized."""
    if _activity_client is None:
        raise RuntimeError(
            "Activity client not initialized. Call initialize_activity_client() at startup."
        )
    return _activity_client


class ActivitySupabaseClient:
    """Handles Supabase operations for activities, comments, kudos, sharing."""

    def __init__(self, supabase_client: Client):
        self._client = supabase_client

    # ------------------------------------------------------------------
    # Activities
    # ------------------------------------------------------------------
    def create_activity(
        self,
        user_id: str,
        name: str,
        start_time: str,
        end_time: str,
        activity_type: str,
        gps_path: list[dict[str, Any]],
        duration_seconds: int,
        distance_meters: float,
        elevation_gain_meters: float,
        visibility: str = "private",
        description: str | None = None,
        map_activity_id: str | None = None,
        processing_status: ProcessingStatus | str = ProcessingStatus.ready,
        storage_key: str | None = None,
        activity_id: str | None = None,
    ) -> dict[str, Any] | None:
        payload: dict[str, Any] = {
            "user_id": user_id,
            "name": name,
            "start_time": start_time,
            "end_time": end_time,
            "activity_type": activity_type,
            "gps_path": gps_path,
            "duration_seconds": duration_seconds,
            "distance_meters": distance_meters,
            "elevation_gain_meters": elevation_gain_meters,
            "visibility": visibility,
            "description": description,
            "created_at": datetime.utcnow().isoformat() + "Z",
        }
        if map_activity_id:
            payload["map_activity_id"] = map_activity_id
        if storage_key:
            payload["storage_key"] = storage_key
        if activity_id:
            payload["id"] = activity_id
        # processing_status: set via update_activity_pipeline_fields after migration 004

        resp = self._client.table("activities").insert(payload).execute()
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    def update_activity_pipeline_fields(
        self,
        activity_id: str,
        user_id: str,
        *,
        map_activity_id: str | None = None,
        processing_status: ProcessingStatus | str | None = None,
        storage_key: str | None = None,
        distance_meters: float | None = None,
        duration_seconds: int | None = None,
        elevation_gain_meters: float | None = None,
        gps_path: list[dict[str, Any]] | None = None,
        thumbnail_url: str | None = None,
        name: str | None = None,
    ) -> dict[str, Any] | None:
        update_fields: dict[str, Any] = {
            "updated_at": datetime.utcnow().isoformat() + "Z",
        }
        if map_activity_id is not None:
            update_fields["map_activity_id"] = map_activity_id
        if processing_status is not None:
            update_fields["processing_status"] = str(processing_status)
        if storage_key is not None:
            update_fields["storage_key"] = storage_key
        if distance_meters is not None:
            update_fields["distance_meters"] = distance_meters
        if duration_seconds is not None:
            update_fields["duration_seconds"] = duration_seconds
        if elevation_gain_meters is not None:
            update_fields["elevation_gain_meters"] = elevation_gain_meters
        if gps_path is not None:
            update_fields["gps_path"] = gps_path
        if thumbnail_url is not None:
            update_fields["thumbnail_url"] = thumbnail_url
        if name is not None:
            update_fields["name"] = name

        resp = (
            self._client.table("activities")
            .update(update_fields)
            .eq("id", activity_id)
            .eq("user_id", user_id)
            .execute()
        )
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    def create_signed_upload_url(
        self,
        bucket: str,
        storage_key: str,
        expires_in: int,
    ) -> dict[str, Any]:
        return self._client.storage.from_(bucket).create_signed_upload_url(
            storage_key,
            expires_in,
        )

    def download_storage_object(self, bucket: str, storage_key: str) -> bytes:
        return self._client.storage.from_(bucket).download(storage_key)

    def following_ids(self, user_id: str) -> list[str]:
        """Ids `user_id` follows, for the visibility filter.

        Reads community-backend's table directly. An HTTP hop would put two
        more round trips in front of every activity list; see
        backend/shared/follow_graph.py. Reads only -- writes stay there.

        Args:
            user_id: The viewer whose follow graph to read.

        Returns:
            Ids of accounts `user_id` follows. Empty on failure or when
            `user_id` is falsy.
        """
        return _following_ids(self._client, user_id)

    def list_activities(
        self,
        viewer_id: str | None = None,
        following: list[str] | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> dict[str, Any]:
        """Activities this viewer may see, newest first.

        This used to be an unfiltered select. It returned every private GPS
        track in the database to an unauthenticated caller.

        Args:
            viewer_id: The caller, or `None` for an anonymous request.
            following: Ids `viewer_id` follows, for the followers-tier clause.
            limit: Max rows to return.
            offset: Rows to skip, for pagination.

        Returns:
            `{"items": [...], "total": n}` -- `total` counts all visible
            rows, not just the returned page.
        """
        resp = (
            self._client.table("activities")
            .select("*", count=CountMethod.exact)
            .or_(visible_rows_expression(viewer_id, following))
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        data = getattr(resp, "data", []) or []
        total = getattr(resp, "count", 0) or 0
        return {"items": data, "total": total}

    def list_user_activities(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
        search: str | None = None,
        activity_type: str | None = None,
        start_date: str | None = None,
        end_date: str | None = None,
    ) -> dict[str, Any]:
        """One user's own activities, newest first.

        Unlike `list_activities` this needs no visibility filter: every row
        it can reach is already the caller's own.

        Args:
            user_id: Whose activities to return.
            limit: Max rows to return.
            offset: Rows to skip, for pagination.
            search: Case-insensitive substring match on the name.
            activity_type: Exact match on the activity type.
            start_date: Inclusive lower bound on `created_at`.
            end_date: Inclusive upper bound on `created_at`.

        Returns:
            `{"items": [...], "total": n}` -- `total` counts all matching
            rows, not just the returned page.
        """
        query = (
            self._client.table("activities")
            .select("*", count=CountMethod.exact)
            .eq("user_id", user_id)
        )
        if activity_type:
            query = query.eq("activity_type", activity_type)
        if search:
            query = query.ilike("name", f"%{search}%")
        if start_date:
            query = query.gte("created_at", start_date)
        if end_date:
            query = query.lte("created_at", end_date)
        # Explicit ordering, not decoration: `range` paginates an unordered
        # result set, so without this a row can appear on two pages or on
        # none. Matches `list_activities`, which the caller may page against
        # interchangeably.
        query = query.order("created_at", desc=True).range(offset, offset + limit - 1)
        resp = query.execute()
        data = getattr(resp, "data", []) or []
        total = getattr(resp, "count", 0) or 0
        return {"items": data, "total": total}

    def get_activity_by_id(self, activity_id: str) -> dict[str, Any] | None:
        resp = self._client.table("activities").select("*").eq("id", activity_id).limit(1).execute()
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    def update_activity(
        self,
        activity_id: str,
        user_id: str,
        name: str | None = None,
        description: str | None = None,
        visibility: str | None = None,
        on_leaderboard: bool | None = None,
    ) -> dict[str, Any] | None:
        update_fields: dict[str, Any] = {}
        if name is not None:
            update_fields["name"] = name
        if description is not None:
            update_fields["description"] = description
        if visibility is not None:
            update_fields["visibility"] = visibility
        if on_leaderboard is not None:
            update_fields["on_leaderboard"] = on_leaderboard
        if not update_fields:
            return self.get_activity_by_id(activity_id)

        resp = (
            self._client.table("activities")
            .update(update_fields)
            .eq("id", activity_id)
            .eq("user_id", user_id)
            .execute()
        )
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    def delete_activity(self, activity_id: str, user_id: str) -> bool:
        resp = (
            self._client.table("activities")
            .delete()
            .eq("id", activity_id)
            .eq("user_id", user_id)
            .execute()
        )
        deleted = getattr(resp, "data", None)
        return bool(deleted)

    # ------------------------------------------------------------------
    # Kudos (like/unlike)
    # ------------------------------------------------------------------
    def toggle_kudos(self, activity_id: str, user_id: str) -> dict[str, Any]:
        existing = (
            self._client.table("activity_kudos")
            .select("id")
            .eq("activity_id", activity_id)
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        rows = getattr(existing, "data", []) or []
        if rows:
            # Unlike
            self._client.table("activity_kudos").delete().eq("id", rows[0]["id"]).execute()
            return {"liked": False}
        else:
            # Like
            payload = {
                "activity_id": activity_id,
                "user_id": user_id,
                "created_at": datetime.utcnow().isoformat() + "Z",
            }
            self._client.table("activity_kudos").insert(payload).execute()
            return {"liked": True}

    # ------------------------------------------------------------------
    # Comments
    # ------------------------------------------------------------------
    def list_comments(self, activity_id: str, limit: int = 50, offset: int = 0) -> dict[str, Any]:
        resp = (
            self._client.table("activity_comments")
            .select("*", count=CountMethod.exact)
            .eq("activity_id", activity_id)
            .order("created_at", desc=False)
            .range(offset, offset + limit - 1)
            .execute()
        )
        data = getattr(resp, "data", []) or []
        total = getattr(resp, "count", 0) or 0
        return {"items": data, "total": total}

    def add_comment(self, activity_id: str, user_id: str, content: str) -> dict[str, Any] | None:
        payload = {
            "activity_id": activity_id,
            "user_id": user_id,
            "content": content,
            "created_at": datetime.utcnow().isoformat() + "Z",
        }
        resp = self._client.table("activity_comments").insert(payload).execute()
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    # ------------------------------------------------------------------
    # Sharing
    # ------------------------------------------------------------------
    def create_share_link(self, activity_id: str, user_id: str) -> dict[str, Any]:
        token = uuid4().hex
        payload = {
            "activity_id": activity_id,
            "user_id": user_id,
            "token": token,
            "created_at": datetime.utcnow().isoformat() + "Z",
        }
        self._client.table("activity_shares").insert(payload).execute()
        return {"share_token": token, "share_url": f"/activities/share/{token}"}
