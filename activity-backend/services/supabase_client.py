"""Supabase client for Activity Backend (skiing activity records)."""
from __future__ import annotations
from typing import Optional, List, Dict, Any
import logging
from uuid import uuid4
from datetime import datetime

from supabase import create_client, Client
from postgrest import CountMethod

from config import get_config

logger = logging.getLogger(__name__)

# Global client instance - initialized at startup
_activity_client: Optional["ActivitySupabaseClient"] = None


def initialize_activity_client() -> "ActivitySupabaseClient":
    """Initialize Supabase client once at application startup."""
    global _activity_client
    config = get_config()
    supabase = create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY)
    _activity_client = ActivitySupabaseClient(supabase)
    logger.info("✅ Activity Supabase client initialized")
    return _activity_client


def get_activity_client() -> "ActivitySupabaseClient":
    """Get initialized Supabase client. Raises if not initialized."""
    if _activity_client is None:
        raise RuntimeError("Activity client not initialized. Call initialize_activity_client() at startup.")
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
        gps_path: List[Dict[str, float]],
        duration_seconds: int,
        distance_meters: float,
        elevation_gain_meters: float,
        visibility: str = "private",
        description: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        payload = {
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
        resp = self._client.table("activities").insert(payload).execute()
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    def list_activities(self, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
        resp = self._client.table("activities").select("*", count=CountMethod.exact).range(offset, offset + limit - 1).execute()
        data = getattr(resp, "data", []) or []
        total = getattr(resp, "count", 0) or 0
        return {"items": data, "total": total}

    def list_user_activities(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
        search: Optional[str] = None,
        activity_type: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
    ) -> Dict[str, Any]:
        query = self._client.table("activities").select("*", count=CountMethod.exact).eq("user_id", user_id)
        if activity_type:
            query = query.eq("activity_type", activity_type)
        if search:
            query = query.ilike("name", f"%{search}%")
        if start_date:
            query = query.gte("created_at", start_date)
        if end_date:
            query = query.lte("created_at", end_date)
        query = query.range(offset, offset + limit - 1)
        resp = query.execute()
        data = getattr(resp, "data", []) or []
        total = getattr(resp, "count", 0) or 0
        return {"items": data, "total": total}

    def get_activity_by_id(self, activity_id: str) -> Optional[Dict[str, Any]]:
        resp = self._client.table("activities").select("*").eq("id", activity_id).limit(1).execute()
        data = getattr(resp, "data", None)
        if isinstance(data, list) and data:
            return data[0]
        return None

    def update_activity(
        self,
        activity_id: str,
        user_id: str,
        name: Optional[str] = None,
        description: Optional[str] = None,
        visibility: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        update_fields = {}
        if name is not None:
            update_fields["name"] = name
        if description is not None:
            update_fields["description"] = description
        if visibility is not None:
            update_fields["visibility"] = visibility
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
        resp = self._client.table("activities").delete().eq("id", activity_id).eq("user_id", user_id).execute()
        deleted = getattr(resp, "data", None)
        return bool(deleted)

    # ------------------------------------------------------------------
    # Kudos (like/unlike)
    # ------------------------------------------------------------------
    def toggle_kudos(self, activity_id: str, user_id: str) -> Dict[str, Any]:
        existing = self._client.table("activity_kudos").select("id").eq("activity_id", activity_id).eq("user_id", user_id).limit(1).execute()
        rows = getattr(existing, "data", []) or []
        if rows:
            # Unlike
            self._client.table("activity_kudos").delete().eq("id", rows[0]["id"]).execute()
            return {"liked": False}
        else:
            # Like
            payload = {"activity_id": activity_id, "user_id": user_id, "created_at": datetime.utcnow().isoformat() + "Z"}
            self._client.table("activity_kudos").insert(payload).execute()
            return {"liked": True}

    # ------------------------------------------------------------------
    # Comments
    # ------------------------------------------------------------------
    def list_comments(self, activity_id: str, limit: int = 50, offset: int = 0) -> Dict[str, Any]:
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

    def add_comment(self, activity_id: str, user_id: str, content: str) -> Optional[Dict[str, Any]]:
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
    def create_share_link(self, activity_id: str, user_id: str) -> Dict[str, Any]:
        token = uuid4().hex
        payload = {
            "activity_id": activity_id,
            "user_id": user_id,
            "token": token,
            "created_at": datetime.utcnow().isoformat() + "Z",
        }
        self._client.table("activity_shares").insert(payload).execute()
        return {"share_token": token, "share_url": f"/activities/share/{token}"}
