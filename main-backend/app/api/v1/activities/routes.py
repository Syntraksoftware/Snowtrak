"""
Activity API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List
from app.schemas.activity import ActivityCreate, ActivityUpdate, ActivityResponse
from app.core.storage import User, Activity, activity_store
from app.core.supabase import supabase_client
from app.api.dependencies import get_current_user
from .helpers import activity_dict_to_response, activity_model_to_response, locations_to_dict
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/activities", tags=["Activities"])


@router.post("/", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
def create_activity(
    activity: ActivityCreate,
    current_user: User = Depends(get_current_user),
) -> ActivityResponse:
    """Create a new activity."""
    locations = locations_to_dict(activity.locations)
    
    if supabase_client.is_configured():
        # is configured = connected, backend activated
        result = supabase_client.create_activity(
            user_id=current_user.id,
            type=activity.type.value,
            distance=activity.distance,
            duration=activity.duration,
            start_time=activity.start_time.isoformat(),
            end_time=activity.end_time.isoformat(),
            name=activity.name,
            description=activity.description,
            elevation_gain=activity.elevation_gain,
            average_pace=activity.average_pace,
            max_pace=activity.max_pace,
            calories=activity.calories,
            is_public=activity.is_public,
            locations=locations,
        )
        if result:
            return activity_dict_to_response(result)
        raise HTTPException(status_code=500, detail="Failed to create activity")
    
    # Fallback to in-memory
    new_activity = Activity(
        user_id=current_user.id, type=activity.type.value,
        distance=activity.distance, duration=activity.duration,
        start_time=activity.start_time, end_time=activity.end_time,
        name=activity.name, description=activity.description,
        elevation_gain=activity.elevation_gain, average_pace=activity.average_pace,
        max_pace=activity.max_pace, calories=activity.calories,
        is_public=activity.is_public, locations=locations,
    )
    activity_store.create(new_activity)
    return activity_model_to_response(new_activity)


@router.get("/", response_model=List[ActivityResponse])
def list_my_activities(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
) -> List[ActivityResponse]:
    """List current user's activities."""
    if supabase_client.is_configured():
        activities = supabase_client.list_activities_by_user(
            user_id=current_user.id, limit=limit, offset=offset,
        )
        return [activity_dict_to_response(a) for a in activities]
    
    activities = activity_store.get_by_user_id(current_user.id, limit, offset)
    return [activity_model_to_response(a) for a in activities]


@router.get("/feed", response_model=List[ActivityResponse])
def get_public_feed(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
) -> List[ActivityResponse]:
    """Get public activity feed."""
    if supabase_client.is_configured():
        activities = supabase_client.list_public_activities(limit=limit, offset=offset)
        return [activity_dict_to_response(a) for a in activities]
    return []


@router.get("/{activity_id}", response_model=ActivityResponse)
def get_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user),
) -> ActivityResponse:
    """Get a specific activity by ID."""
    if supabase_client.is_configured():
        activity = supabase_client.get_activity_by_id(activity_id)
        if not activity:
            raise HTTPException(status_code=404, detail="Activity not found")
        if activity["user_id"] != current_user.id and not activity.get("is_public"):
            raise HTTPException(status_code=403, detail="Not authorized")
        return activity_dict_to_response(activity)
    
    activity = activity_store.get_by_id(activity_id)
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    if activity.user_id != current_user.id and not activity.is_public:
        raise HTTPException(status_code=403, detail="Not authorized")
    return activity_model_to_response(activity)


@router.put("/{activity_id}", response_model=ActivityResponse)
def update_activity(
    activity_id: str,
    update: ActivityUpdate,
    current_user: User = Depends(get_current_user),
) -> ActivityResponse:
    """Update an activity (name, description, is_public only)."""
    if supabase_client.is_configured():
        result = supabase_client.update_activity(
            activity_id=activity_id, user_id=current_user.id,
            name=update.name, description=update.description, is_public=update.is_public,
        )
        if not result:
            raise HTTPException(status_code=404, detail="Activity not found or not authorized")
        activity = supabase_client.get_activity_by_id(activity_id)
        return activity_dict_to_response(activity)
    
    activity = activity_store.get_by_id(activity_id)
    if not activity or activity.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Activity not found or not authorized")
    activity_store.update(activity_id, name=update.name, description=update.description, is_public=update.is_public)
    return activity_model_to_response(activity_store.get_by_id(activity_id))


@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user),
):
    """Delete an activity."""
    if supabase_client.is_configured():
        if not supabase_client.delete_activity(activity_id, current_user.id):
            raise HTTPException(status_code=404, detail="Activity not found or not authorized")
        return
    
    activity = activity_store.get_by_id(activity_id)
    if not activity or activity.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Activity not found or not authorized")
    activity_store.delete(activity_id)
