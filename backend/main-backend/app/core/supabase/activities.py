"""Activity database operations."""

from __future__ import annotations

import logging
from typing import Any

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class ActivityOperations(SupabaseBase):
    """Activity table operations for activities and activity_locations."""

    def create_activity(
        self,
        user_id: str,
        type: str,
        distance: float,
        duration: int,
        start_time: str,
        end_time: str,
        name: str | None = None,
        description: str | None = None,
        elevation_gain: float = 0,
        average_pace: float = 0,
        max_pace: float = 0,
        calories: int | None = None,
        is_public: bool = True,
        locations: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any] | None:
        """Create a new activity with optional GPS locations."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_activity.")
            return None

        client = self._client
        if client is None:
            return None

        try:
            payload = {
                "user_id": user_id,
                "type": type,
                "name": name,
                "description": description,
                "distance": distance,
                "duration": duration,
                "elevation_gain": elevation_gain,
                "start_time": start_time,
                "end_time": end_time,
                "average_pace": average_pace,
                "max_pace": max_pace,
                "calories": calories,
                "is_public": is_public,
            }
            resp = client.table("activities").insert(payload).execute()
            data = getattr(resp, "data", None)

            if not isinstance(data, list) or not data:
                logger.error("Failed to create activity")
                return None

            activity = data[0]
            activity_id = activity["id"]

            if locations:
                location_payloads = [
                    {
                        "activity_id": activity_id,
                        "latitude": loc["latitude"],
                        "longitude": loc["longitude"],
                        "altitude": loc.get("altitude"),
                        "accuracy": loc.get("accuracy"),
                        "speed": loc.get("speed"),
                        "timestamp": loc["timestamp"],
                        "point_order": idx,
                    }
                    for idx, loc in enumerate(locations)
                ]
                client.table("activity_locations").insert(location_payloads).execute()

            activity["locations"] = locations or []
            logger.info(f"Created activity {activity_id} for user {user_id}")
            return activity

        except Exception as exc:
            logger.exception(f"Failed to create activity: {exc}")
            return None

    def get_activity_by_id(self, activity_id: str) -> dict[str, Any] | None:
        """Get activity by ID with locations."""
        if not self.is_configured():
            return None

        client = self._client
        if client is None:
            return None

        try:
            resp = client.table("activities").select("*").eq("id", activity_id).limit(1).execute()
            data = getattr(resp, "data", None)

            if not isinstance(data, list) or not data:
                return None

            activity = data[0]
            loc_resp = (
                client.table("activity_locations")
                .select("*")
                .eq("activity_id", activity_id)
                .order("point_order")
                .execute()
            )
            activity["locations"] = getattr(loc_resp, "data", None) or []
            return activity

        except Exception as exc:
            logger.exception(f"Failed to get activity {activity_id}: {exc}")
            return None

    def list_activities_by_user(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """List activities for a user, newest first."""
        if not self.is_configured():
            return []

        client = self._client
        if client is None:
            return []

        try:
            resp = (
                client.table("activities")
                .select("*")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )

            activities = getattr(resp, "data", None) or []
            for activity in activities:
                activity["locations"] = []
            return activities

        except Exception as exc:
            logger.exception(f"Failed to list activities for user {user_id}: {exc}")
            return []

    def list_public_activities(self, limit: int = 20, offset: int = 0) -> list[dict[str, Any]]:
        """List public activities for feed, newest first."""
        if not self.is_configured():
            return []

        client = self._client
        if client is None:
            return []

        try:
            resp = (
                client.table("activities")
                .select("*, user_info!activities_user_id_fkey(email, first_name, last_name)")
                .eq("is_public", True)
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )

            activities = getattr(resp, "data", None) or []
            for activity in activities:
                if "user_info" in activity and activity["user_info"]:
                    user = activity.pop("user_info")
                    activity["user_email"] = user.get("email")
                    activity["user_first_name"] = user.get("first_name")
                    activity["user_last_name"] = user.get("last_name")
                activity["locations"] = []
            return activities

        except Exception as exc:
            logger.exception(f"Failed to list public activities: {exc}")
            return []

    def update_activity(
        self,
        activity_id: str,
        user_id: str,
        name: str | None = None,
        description: str | None = None,
        is_public: bool | None = None,
    ) -> dict[str, Any] | None:
        """Update activity (only name, description, is_public)."""
        if not self.is_configured():
            return None

        client = self._client
        if client is None:
            return None

        try:
            activity = self.get_activity_by_id(activity_id)
            if not activity or activity["user_id"] != user_id:
                logger.warning(f"Activity {activity_id} not found or unauthorized")
                return None

            update_data: dict[str, Any] = {}
            if name is not None:
                update_data["name"] = name
            if description is not None:
                update_data["description"] = description
            if is_public is not None:
                update_data["is_public"] = is_public

            if not update_data:
                return activity

            resp = client.table("activities").update(update_data).eq("id", activity_id).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Updated activity {activity_id}")
                return data[0]
            return None

        except Exception as exc:
            logger.exception(f"Failed to update activity {activity_id}: {exc}")
            return None

    def delete_activity(self, activity_id: str, user_id: str) -> bool:
        """Delete activity and its locations (CASCADE)."""
        if not self.is_configured():
            return False

        client = self._client
        if client is None:
            return False

        try:
            activity = self.get_activity_by_id(activity_id)
            if not activity or activity["user_id"] != user_id:
                logger.warning(f"Activity {activity_id} not found or unauthorized")
                return False

            resp = client.table("activities").delete().eq("id", activity_id).execute()
            if isinstance(getattr(resp, "data", None), list):
                logger.info(f"Deleted activity {activity_id}")
                return True
            return False

        except Exception as exc:
            logger.exception(f"Failed to delete activity {activity_id}: {exc}")
            return False
