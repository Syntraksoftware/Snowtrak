"""
Activity helper functions for response conversion.
"""

from app.core.storage import Activity
from app.schemas.activity import ActivityResponse, LocationResponse


def activity_dict_to_response(activity: dict) -> ActivityResponse:
    """Convert database dict to ActivityResponse."""
    locations = [
        LocationResponse(
            latitude=loc["latitude"],
            longitude=loc["longitude"],
            altitude=loc.get("altitude", 0),
            accuracy=loc.get("accuracy"),
            speed=loc.get("speed"),
            timestamp=loc["timestamp"],
        )
        for loc in activity.get("locations", [])
    ]
    return ActivityResponse(
        id=activity["id"],
        user_id=activity["user_id"],
        type=activity["type"],
        name=activity.get("name"),
        description=activity.get("description"),
        distance=activity["distance"],
        duration=activity["duration"],
        elevation_gain=activity.get("elevation_gain", 0),
        start_time=activity["start_time"],
        end_time=activity["end_time"],
        average_pace=activity.get("average_pace", 0),
        max_pace=activity.get("max_pace", 0),
        calories=activity.get("calories"),
        is_public=activity.get("is_public", True),
        created_at=activity["created_at"],
        locations=locations,
    )


def activity_model_to_response(activity: Activity) -> ActivityResponse:
    """Convert in-memory Activity model to ActivityResponse."""
    return ActivityResponse(
        id=activity.id,
        user_id=activity.user_id,
        type=activity.type,
        name=activity.name,
        description=activity.description,
        distance=activity.distance,
        duration=activity.duration,
        elevation_gain=activity.elevation_gain,
        start_time=activity.start_time,
        end_time=activity.end_time,
        average_pace=activity.average_pace,
        max_pace=activity.max_pace,
        calories=activity.calories,
        is_public=activity.is_public,
        created_at=activity.created_at,
        locations=[],
    )


def locations_to_dict(locations: list) -> list[dict]:
    """Convert LocationCreate list to dict format for storage."""
    return [
        {
            "latitude": loc.latitude,
            "longitude": loc.longitude,
            "altitude": loc.altitude,
            "accuracy": loc.accuracy,
            "speed": loc.speed,
            "timestamp": loc.timestamp.isoformat(),
        }
        for loc in locations
    ]
