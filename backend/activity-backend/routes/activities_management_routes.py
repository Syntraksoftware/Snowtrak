"""Core create, read, update, and delete routes for activities."""

import asyncio
import logging

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from shared.pipeline_enums import ProcessingStatus
from shared.visibility import can_view

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
from services.activity_deletion_service import ActivityDeletionService
from services.map_backend_client import get_map_backend_client
from services.offload import offload
from services.supabase_client import get_activity_client
from services.user_stats_service import get_stats_service

logger = logging.getLogger(__name__)
router = APIRouter()


async def _background_thumbnail(activity_id: str, user_id: str, gps_path: list[dict]) -> None:
    """Generate thumbnail after response is sent; failure is non-fatal."""
    try:
        thumbnail_url = await get_map_backend_client().generate_thumbnail(activity_id, gps_path)
        if thumbnail_url:
            get_activity_client().update_activity_pipeline_fields(
                activity_id, user_id, thumbnail_url=thumbnail_url
            )
    except Exception:
        logger.warning("background thumbnail failed for activity %s", activity_id, exc_info=True)


@router.post("/", response_model=FrontendActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    data: FrontendActivityCreate,
    background_tasks: BackgroundTasks,
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
            map_activity_id=data.map_activity_id,
            processing_status=data.processing_status or ProcessingStatus.ready,
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
        background_tasks.add_task(
            _background_thumbnail, created_activity["id"], user_id, gps_path_records
        )
        background_tasks.add_task(get_stats_service().recompute_and_upsert, user_id)
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
        # The activity read and the follow lookup are independent -- the
        # latter only needs user_id, not the row -- and the database is a
        # continent away, so run them concurrently instead of back to back.
        # Skip the follow lookup entirely for an anonymous caller.
        if user_id:
            activity_record, following = await asyncio.gather(
                offload(activity_client.get_activity_by_id, activity_id),
                offload(activity_client.following_ids, user_id),
            )
        else:
            activity_record = await offload(activity_client.get_activity_by_id, activity_id)
            following = []

        if not activity_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found",
            ) from None

        if not can_view(activity_record, user_id, following):
            # 404, not 403: a private activity's existence is itself private.
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
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_current_user),
):
    """Delete an activity owned by the authenticated user."""
    activity_client = get_activity_client()
    deletion_service = ActivityDeletionService(activity_client)
    try:
        is_deleted = await deletion_service.delete_activity(activity_id, user_id)
        if not is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found or not authorized",
            ) from None

        background_tasks.add_task(get_stats_service().recompute_and_upsert, user_id)
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
