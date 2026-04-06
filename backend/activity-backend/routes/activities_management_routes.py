"""Core create, read, update, and delete routes for activities."""

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from middleware.auth import get_current_user, get_optional_user
from models import (
    DeleteResponse,
    FrontendActivityCreate,
    FrontendActivityResponse,
    FrontendActivityUpdate,
)
from routes.activity_transformers import (
    compute_metrics_from_locations,
    convert_to_location_points,
    map_activity_to_frontend_payload,
    parse_iso_timestamp,
)
from services.supabase_client import get_activity_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/", response_model=FrontendActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    data: FrontendActivityCreate,
    user_id: str = Depends(get_current_user),
):
    """Create a new activity and return frontend response shape."""
    activity_client = get_activity_client()
    try:
        start_time = parse_iso_timestamp(data.start_time)
        end_time = parse_iso_timestamp(data.end_time)
        duration_seconds = max(0, int((end_time - start_time).total_seconds()))

        location_records = [location.model_dump() for location in data.locations]
        computed_metrics = compute_metrics_from_locations(location_records)
        gps_path_records = [
            location_point.model_dump()
            for location_point in convert_to_location_points(location_records)
        ]

        visibility_value = "private"
        if data.is_public is True:
            visibility_value = "public"

        created_activity = activity_client.create_activity(
            user_id=user_id,
            name=data.name or "Untitled Activity",
            start_time=start_time.isoformat(),
            end_time=end_time.isoformat(),
            activity_type=data.type,
            gps_path=gps_path_records,
            duration_seconds=duration_seconds,
            distance_meters=computed_metrics["distance_meters"],
            elevation_gain_meters=computed_metrics["elevation_gain_meters"],
            visibility=visibility_value,
            description=data.description,
        )

        if not created_activity:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create activity",
            ) from None

        frontend_payload = map_activity_to_frontend_payload(
            created_activity,
            fallback_start_time=data.start_time,
            fallback_end_time=data.end_time,
        )
        return FrontendActivityResponse(**frontend_payload)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error creating activity: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/{activity_id}", response_model=FrontendActivityResponse)
async def get_activity(
    activity_id: str,
    user_id: str | None = Depends(get_optional_user),
):
    """Get activity details formatted for frontend."""
    activity_client = get_activity_client()
    try:
        activity_record = activity_client.get_activity_by_id(activity_id)
        if not activity_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found",
            ) from None

        visibility = str(activity_record.get("visibility", "private")).lower()
        owner_id = str(activity_record.get("user_id", ""))
        can_view = visibility == "public" or (user_id is not None and user_id == owner_id)
        if not can_view:
            # Intentionally return 404 to avoid exposing private resource existence.
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found",
            ) from None

        frontend_payload = map_activity_to_frontend_payload(activity_record)
        return FrontendActivityResponse(**frontend_payload)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error getting activity: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.put("/{activity_id}", response_model=FrontendActivityResponse)
async def update_activity(
    activity_id: str,
    data: FrontendActivityUpdate,
    user_id: str = Depends(get_current_user),
):
    """Update an activity and return frontend response shape."""
    activity_client = get_activity_client()
    try:
        visibility_value = None
        if data.is_public is True:
            visibility_value = "public"
        if data.is_public is False:
            visibility_value = "private"

        updated_activity = activity_client.update_activity(
            activity_id=activity_id,
            user_id=user_id,
            name=data.name,
            description=data.description,
            visibility=visibility_value,
        )

        if not updated_activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found or not authorized",
            ) from None

        frontend_payload = map_activity_to_frontend_payload(updated_activity)
        return FrontendActivityResponse(**frontend_payload)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error updating activity: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.delete("/{activity_id}", response_model=DeleteResponse)
async def delete_activity(
    activity_id: str,
    user_id: str = Depends(get_current_user),
):
    """Delete an activity owned by the authenticated user."""
    activity_client = get_activity_client()
    try:
        is_deleted = activity_client.delete_activity(activity_id, user_id)
        if not is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found or not authorized",
            ) from None

        return DeleteResponse(
            message="Activity deleted",
            deleted_activity_id=activity_id,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error deleting activity: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None
