"""Activity routes for skiing activity records (minimal FastAPI implementation)."""
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query
import logging
from datetime import datetime
import math

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_activity_client
from models import (
    ActivityCreate,
    ActivityUpdate,
    ActivityResponse,
    ActivitiesListResponse,
    CommentCreate,
    CommentResponse,
    CommentsListResponse,
    ToggleKudosResponse,
    ShareLinkResponse,
    DeleteResponse,
    FrontendActivityCreate,
    FrontendActivityResponse,
    FrontendActivityUpdate,
    LocationPoint,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/activities", tags=["activities"])


# -----------------------
# Routes
# -----------------------
def _parse_iso(ts: str) -> datetime:
    # Accept 'Z' suffix by converting to offset-aware ISO
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))

def _haversine_distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000.0  # meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def _compute_metrics_from_locations(locations: List[Dict[str, Any]]) -> Dict[str, float]:
    distance = 0.0
    elevation_gain = 0.0
    for i in range(1, len(locations)):
        p1 = locations[i-1]
        p2 = locations[i]
        distance += _haversine_distance_m(p1["latitude"], p1["longitude"], p2["latitude"], p2["longitude"])
        alt1 = p1.get("altitude")
        alt2 = p2.get("altitude")
        if alt1 is not None and alt2 is not None:
            delta = float(alt2) - float(alt1)
            if delta > 0:
                elevation_gain += delta
    return {"distance_meters": distance, "elevation_gain_meters": elevation_gain}

def _to_location_points(locations: List[Dict[str, Any]]) -> List[LocationPoint]:
    return [
        LocationPoint(
            lat=loc["latitude"],
            lng=loc["longitude"],
            elevation=loc.get("altitude"),
            timestamp=loc.get("timestamp"),
        )
        for loc in locations
    ]

def _to_frontend_locations(activity_id: str, gps_path: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    frontend_locs = []
    for p in gps_path:
        lat = p.get("lat") if isinstance(p, dict) else None
        lng = p.get("lng") if isinstance(p, dict) else None
        if lat is None or lng is None:
            continue
        frontend_locs.append(
            {
                "id": None,
                "activity_id": activity_id,
                "latitude": lat,
                "longitude": lng,
                "altitude": p.get("elevation") if isinstance(p, dict) else None,
                "accuracy": None,
                "speed": None,
                "timestamp": p.get("timestamp") if isinstance(p, dict) else None,
            }
        )
    return frontend_locs

def _activity_to_frontend(activity: Dict[str, Any], fallback_start: Optional[str] = None, fallback_end: Optional[str] = None) -> Dict[str, Any]:
    """Map a backend activity record into the frontend-facing schema."""
    distance_meters = activity.get("distance_meters") or activity.get("distance") or 0
    duration_seconds = activity.get("duration_seconds") or activity.get("duration") or 0
    elevation_gain = activity.get("elevation_gain_meters") or activity.get("elevation_gain") or 0
    start_time = activity.get("start_time") or fallback_start or activity.get("created_at") or datetime.utcnow().isoformat()
    end_time = activity.get("end_time") or fallback_end or activity.get("created_at") or datetime.utcnow().isoformat()
    if isinstance(start_time, datetime):
        start_time = start_time.isoformat()
    if isinstance(end_time, datetime):
        end_time = end_time.isoformat()

    avg_pace = None
    try:
        if distance_meters and distance_meters > 0:
            avg_pace = duration_seconds / (distance_meters / 1000)
    except Exception:
        avg_pace = None

    created_at = activity.get("created_at")
    if isinstance(created_at, datetime):
        created_at = created_at.isoformat()

    gps_path = activity.get("gps_path", []) or []

    return {
        "id": activity.get("id"),
        "user_id": activity.get("user_id"),
        "type": activity.get("activity_type") or activity.get("type") or "other",
        "name": activity.get("name"),
        "description": activity.get("description"),
        "distance": distance_meters,
        "duration": duration_seconds,
        "elevation_gain": elevation_gain,
        "start_time": start_time,
        "end_time": end_time,
        "average_pace": avg_pace,
        "max_pace": activity.get("max_pace"),
        "calories": activity.get("calories"),
        "is_public": (activity.get("visibility") == "public"),
        "created_at": created_at,
        "locations": _to_frontend_locations(activity.get("id"), gps_path),
    }

@router.post("", response_model=FrontendActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    data: FrontendActivityCreate,
    user_id: str = Depends(get_current_user)
):
    """Create a new activity (authenticated) aligned to frontend payload and response."""
    client = get_activity_client()
    try:
        # Derive metrics
        start_dt = _parse_iso(data.start_time)
        end_dt = _parse_iso(data.end_time)
        duration_seconds = max(0, int((end_dt - start_dt).total_seconds()))
        metrics = _compute_metrics_from_locations([loc.model_dump() for loc in data.locations])
        gps_path = [pt.model_dump() for pt in _to_location_points([loc.model_dump() for loc in data.locations])]
        visibility = "public" if data.is_public else "private"

        result = client.create_activity(
            user_id=user_id,
            name=data.name or "Untitled Activity",
            start_time=start_dt.isoformat(),
            end_time=end_dt.isoformat(),
            activity_type=data.type,
            gps_path=gps_path,
            duration_seconds=duration_seconds,
            distance_meters=metrics["distance_meters"],
            elevation_gain_meters=metrics["elevation_gain_meters"],
            visibility=visibility,
            description=data.description,
        )
        if not result:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create activity")

        # Shape response for the frontend
        distance_meters = result.get("distance_meters", metrics["distance_meters"])  # type: ignore
        duration_s = result.get("duration_seconds", duration_seconds)  # type: ignore
        avg_pace = (duration_s / (distance_meters/1000)) if distance_meters and distance_meters > 0 else None

        frontend_resp = {
            "id": result.get("id"),
            "user_id": result.get("user_id"),
            "type": result.get("activity_type", data.type),
            "name": result.get("name"),
            "description": result.get("description"),
            "distance": distance_meters,
            "duration": duration_s,
            "elevation_gain": result.get("elevation_gain_meters", metrics["elevation_gain_meters"]),
            "start_time": data.start_time,
            "end_time": data.end_time,
            "average_pace": avg_pace,
            "max_pace": None,
            "calories": None,
            "is_public": (result.get("visibility") == "public"),
            "created_at": result.get("created_at"),
            "locations": _to_frontend_locations(result.get("id"), result.get("gps_path", [])),
        }
        return FrontendActivityResponse(**frontend_resp)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error creating activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("", response_model=List[FrontendActivityResponse])
async def list_activities(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """List activities (public feed) formatted for frontend."""
    client = get_activity_client()
    try:
        resp = client.list_activities(limit=limit, offset=offset)
        items = resp["items"] if isinstance(resp, dict) else resp
        return [FrontendActivityResponse(**_activity_to_frontend(item)) for item in items]
    except Exception as exc:
        logger.error(f"Error listing activities: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("/me", response_model=List[FrontendActivityResponse])
async def list_my_activities(
    search: Optional[str] = None,
    activity_type: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user_id: str = Depends(get_current_user),
):
    """List current user's activities with optional filters, frontend shape."""
    client = get_activity_client()
    try:
        resp = client.list_user_activities(
            user_id=user_id,
            limit=limit,
            offset=offset,
            search=search,
            activity_type=activity_type,
            start_date=start_date,
            end_date=end_date,
        )
        items = resp["items"] if isinstance(resp, dict) else resp
        return [FrontendActivityResponse(**_activity_to_frontend(item)) for item in items]
    except Exception as exc:
        logger.error(f"Error listing user activities: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("/{activity_id}", response_model=FrontendActivityResponse)
async def get_activity(activity_id: str, user_id: Optional[str] = Depends(get_optional_user)):
    """Get activity details formatted for frontend."""
    client = get_activity_client()
    try:
        activity = client.get_activity_by_id(activity_id)
        if not activity:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found")
        return FrontendActivityResponse(**_activity_to_frontend(activity))
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error getting activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.put("/{activity_id}", response_model=FrontendActivityResponse)
async def update_activity(
    activity_id: str,
    data: FrontendActivityUpdate,
    user_id: str = Depends(get_current_user)
):
    """Update an activity (owner only) and return frontend shape."""
    client = get_activity_client()
    try:
        visibility = None
        if data.is_public is True:
            visibility = "public"
        elif data.is_public is False:
            visibility = "private"

        updated = client.update_activity(
            activity_id=activity_id,
            user_id=user_id,
            name=data.name,
            description=data.description,
            visibility=visibility,
        )
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found or not authorized")
        return FrontendActivityResponse(**_activity_to_frontend(updated))
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error updating activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.delete("/{activity_id}", response_model=DeleteResponse)
async def delete_activity(activity_id: str, user_id: str = Depends(get_current_user)):
    """Delete an activity (owner only)."""
    client = get_activity_client()
    try:
        ok = client.delete_activity(activity_id, user_id)
        if not ok:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found or not authorized")
        return DeleteResponse(message="Activity deleted", deleted_activity_id=activity_id)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error deleting activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.post("/{activity_id}/kudos", response_model=ToggleKudosResponse)
async def toggle_kudos(activity_id: str, user_id: str = Depends(get_current_user)):
    """Like/unlike an activity."""
    client = get_activity_client()
    try:
        result = client.toggle_kudos(activity_id, user_id)
        return ToggleKudosResponse(**result)
    except Exception as exc:
        logger.error(f"Error toggling kudos: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("/{activity_id}/comments", response_model=CommentsListResponse)
async def list_comments(activity_id: str, limit: int = Query(50, ge=1, le=200), offset: int = Query(0, ge=0)):
    """Get comments for an activity."""
    client = get_activity_client()
    try:
        resp = client.list_comments(activity_id, limit=limit, offset=offset)
        return CommentsListResponse(items=resp["items"], total=resp["total"])
    except Exception as exc:
        logger.error(f"Error listing activity comments: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.post("/{activity_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def add_comment(activity_id: str, data: CommentCreate, user_id: str = Depends(get_current_user)):
    """Add a comment to an activity."""
    client = get_activity_client()
    try:
        comment = client.add_comment(activity_id, user_id, data.content)
        if not comment:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to add comment")
        return comment
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error adding comment: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.post("/{activity_id}/share", response_model=ShareLinkResponse)
async def create_share_link(activity_id: str, user_id: str = Depends(get_current_user)):
    """Generate a shareable link for an activity."""
    client = get_activity_client()
    try:
        share = client.create_share_link(activity_id, user_id)
        return ShareLinkResponse(**share)
    except Exception as exc:
        logger.error(f"Error creating share link: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")
