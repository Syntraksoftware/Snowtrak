"""Activity routes for skiing activity records (minimal FastAPI implementation)."""
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field
import logging

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_activity_client

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/activities", tags=["activities"])


# -----------------------
# Pydantic models
# -----------------------
class LocationPoint(BaseModel):
    lat: float
    lng: float
    elevation: Optional[float] = None
    timestamp: Optional[str] = None  # ISO string


class ActivityCreate(BaseModel):
    name: str = Field(..., description="Activity name")
    activity_type: str = Field(..., description="e.g., ski, snowboard")
    gps_path: List[LocationPoint] = Field(default_factory=list)
    duration_seconds: int
    distance_meters: float
    elevation_gain_meters: float
    visibility: str = Field("private", description="private|followers|public")
    description: Optional[str] = None


class ActivityUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    visibility: Optional[str] = None


class ActivityResponse(BaseModel):
    id: str
    user_id: str
    name: str
    activity_type: str
    gps_path: List[LocationPoint]
    duration_seconds: int
    distance_meters: float
    elevation_gain_meters: float
    visibility: Optional[str] = None
    description: Optional[str] = None
    created_at: Optional[str] = None


class ActivitiesListResponse(BaseModel):
    items: List[ActivityResponse]
    total: int


class CommentCreate(BaseModel):
    content: str


class CommentResponse(BaseModel):
    id: Optional[str] = None
    activity_id: str
    user_id: str
    content: str
    created_at: Optional[str] = None


class CommentsListResponse(BaseModel):
    items: List[CommentResponse]
    total: int


class ToggleKudosResponse(BaseModel):
    liked: bool


class ShareLinkResponse(BaseModel):
    share_token: str
    share_url: str


class DeleteResponse(BaseModel):
    message: str
    deleted_activity_id: Optional[str] = None


# -----------------------
# Routes
# -----------------------
@router.post("", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    data: ActivityCreate,
    user_id: str = Depends(get_current_user)
):
    """Create a new activity (authenticated)."""
    client = get_activity_client()
    try:
        result = client.create_activity(
            user_id=user_id,
            name=data.name,
            activity_type=data.activity_type,
            gps_path=[point.model_dump() for point in data.gps_path],
            duration_seconds=data.duration_seconds,
            distance_meters=data.distance_meters,
            elevation_gain_meters=data.elevation_gain_meters,
            visibility=data.visibility,
            description=data.description,
        )
        if not result:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create activity")
        return result
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error creating activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("", response_model=ActivitiesListResponse)
async def list_activities(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """List activities (public feed)."""
    client = get_activity_client()
    try:
        resp = client.list_activities(limit=limit, offset=offset)
        return ActivitiesListResponse(items=resp["items"], total=resp["total"])
    except Exception as exc:
        logger.error(f"Error listing activities: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("/me", response_model=ActivitiesListResponse)
async def list_my_activities(
    search: Optional[str] = None,
    activity_type: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user_id: str = Depends(get_current_user),
):
    """List current user's activities with optional filters."""
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
        return ActivitiesListResponse(items=resp["items"], total=resp["total"])
    except Exception as exc:
        logger.error(f"Error listing user activities: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.get("/{activity_id}", response_model=ActivityResponse)
async def get_activity(activity_id: str, user_id: Optional[str] = Depends(get_optional_user)):
    """Get activity details."""
    client = get_activity_client()
    try:
        activity = client.get_activity_by_id(activity_id)
        if not activity:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found")
        # Visibility checks could be added here (visibility vs user_id)
        return activity
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error getting activity: {exc}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")


@router.put("/{activity_id}", response_model=ActivityResponse)
async def update_activity(
    activity_id: str,
    data: ActivityUpdate,
    user_id: str = Depends(get_current_user)
):
    """Update an activity (owner only)."""
    client = get_activity_client()
    try:
        updated = client.update_activity(
            activity_id=activity_id,
            user_id=user_id,
            name=data.name,
            description=data.description,
            visibility=data.visibility,
        )
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found or not authorized")
        return updated
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
