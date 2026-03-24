"""Activity routes for skiing activity records (minimal FastAPI implementation)."""
from typing import Optional, List, Dict, Any, Union
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
import logging
from datetime import datetime
import math
import sys
import os

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_activity_client
from shared import ListResponse, ListMeta, PaginationMeta, ResponseMeta, get_request_id
from shared.query_migration import check_deprecated_params, FILTER_MAPPING
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
    dphi = phi2 - phi1
    lambda1 = math.radians(lon1)
    lambda2 = math.radians(lon2)
    dlambda = lambda2 - lambda1
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

        # Shape response for the frontend using the shared helper
        frontend_resp = _activity_to_frontend(
            result,
            fallback_start=data.start_time,
            fallback_end=data.end_time,
        )
        return FrontendActivityResponse(**frontend_resp)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error creating activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("", response_model=Union[ListResponse, List[FrontendActivityResponse]])
async def list_activities(
    request: Request,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    format: Optional[str] = Query(None, description="Response format: 'standard' for {items, meta} or 'legacy' for raw list")
):
    """
    List activities (public feed) formatted for frontend.
    
    Supports both new standardized format and legacy raw list format.
    Default is new standardized format for new clients.
    """
    client = get_activity_client()
    try:
        resp = client.list_activities(limit=limit, offset=offset)
        items = resp["items"] if isinstance(resp, dict) else resp
        total = resp.get("total", len(items))
        
        # Convert to frontend format
        frontend_items = [FrontendActivityResponse(**_activity_to_frontend(item)) for item in items]
        
        # Default to new format unless explicitly requesting legacy
        if format == "legacy":
            return frontend_items
        
        # Return standardized list response
        request_id = get_request_id(request)
        pagination_meta = PaginationMeta(
            limit=limit,
            offset=offset,
            total=total,
            next_cursor=None,  # Placeholder for cursor-based pagination
            has_next=offset + limit < total,
        )
        response_meta = ListMeta(
            request_id=request_id,
            pagination=pagination_meta,
        )
        
        return ListResponse(items=frontend_items, meta=response_meta)
    except Exception as exc:
        logger.error(f"Error listing activities: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to retrieve activities")


@router.get("/me", response_model=Union[ListResponse, List[FrontendActivityResponse]])
async def list_my_activities(
    request: Request,
    search: Optional[str] = None,
    activity_type: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    format: Optional[str] = Query(None, description="Response format: 'standard' for {items, meta} or 'legacy' for raw list"),
    user_id: str = Depends(get_current_user),
):
    """
    List current user's activities with optional filters.
    
    Supports both new standardized format and legacy raw list format.
    Default is new standardized format for new clients.
    
    Filter Parameters:
    - search: Full-text search on activity name
    - activity_type: Filter by activity type (e.g., 'skiing', 'snowboarding')
    - start_date: ISO 8601 date to filter activities from this date onwards
    - end_date: ISO 8601 date to filter activities until this date
    """
    client = get_activity_client()
    try:
        # Soft-accept: check if deprecated parameters are being used
        deprecated_params = check_deprecated_params(request.query_params, FILTER_MAPPING)
        
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
        total = resp.get("total", len(items))
        
        # Convert to frontend format
        frontend_items = [FrontendActivityResponse(**_activity_to_frontend(item)) for item in items]
        
        # Default to new format unless explicitly requesting legacy
        if format == "legacy":
            return frontend_items
        
        # Return standardized list response
        request_id = get_request_id(request)
        pagination_meta = PaginationMeta(
            limit=limit,
            offset=offset,
            total=total,
            next_cursor=None,  # Placeholder for cursor-based pagination
            has_next=offset + limit < total,
        )
        response_meta = ListMeta(
            request_id=request_id,
            pagination=pagination_meta,
            deprecated_params=deprecated_params if deprecated_params else None,
            deprecation_info="Parameters like 'q' (search), 'from' (start_date), 'to' (end_date) are deprecated. Use canonical names instead." if deprecated_params else None,
        )
        
        return ListResponse(items=frontend_items, meta=response_meta)
    except Exception as exc:
        logger.error(f"Error listing user activities: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to retrieve user activities")


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
