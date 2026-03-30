"""List routes for activity feed and current user activities."""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status

from middleware.auth import get_current_user
from models import FrontendActivityResponse
from routes.activity_transformers import (
    build_activity_list_response,
    map_activity_to_frontend_payload,
)
from services.supabase_client import get_activity_client
from shared import ListResponse
from shared.query_migration import FILTER_MAPPING, check_deprecated_params

logger = logging.getLogger(__name__)
router = APIRouter()


def _convert_activity_records_to_frontend_items(activity_records):
    return [
        FrontendActivityResponse(**map_activity_to_frontend_payload(activity_record))
        for activity_record in activity_records
    ]


@router.get("/", response_model=ListResponse)
async def list_activities(
    request: Request,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """List public activities in standardized response format."""
    activity_client = get_activity_client()
    try:
        activity_list_response = activity_client.list_activities(limit=limit, offset=offset)
        if not isinstance(activity_list_response, dict):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Activity list response was not in expected format",
            )

        activity_records = activity_list_response.get("items", [])
        total_items = activity_list_response.get("total", len(activity_records))
        frontend_items = _convert_activity_records_to_frontend_items(activity_records)

        return build_activity_list_response(
            request=request,
            frontend_items=frontend_items,
            limit=limit,
            offset=offset,
            total=total_items,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error listing activities: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve activities",
        )


@router.get("/me", response_model=ListResponse)
async def list_my_activities(
    request: Request,
    search: Optional[str] = None,
    activity_type: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user_id: str = Depends(get_current_user),
):
    """List activities for the authenticated user with optional filters."""
    activity_client = get_activity_client()
    try:
        deprecated_parameters = check_deprecated_params(request.query_params, FILTER_MAPPING)
        user_activity_list_response = activity_client.list_user_activities(
            user_id=user_id,
            limit=limit,
            offset=offset,
            search=search,
            activity_type=activity_type,
            start_date=start_date,
            end_date=end_date,
        )

        if not isinstance(user_activity_list_response, dict):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User activity list response was not in expected format",
            )

        activity_records = user_activity_list_response.get("items", [])
        total_items = user_activity_list_response.get("total", len(activity_records))
        frontend_items = _convert_activity_records_to_frontend_items(activity_records)

        deprecation_information = None
        if deprecated_parameters:
            deprecation_information = (
                "Parameters like 'q' (search), 'from' (start_date), and 'to' "
                "(end_date) are deprecated. Use canonical names instead."
            )

        return build_activity_list_response(
            request=request,
            frontend_items=frontend_items,
            limit=limit,
            offset=offset,
            total=total_items,
            deprecated_parameters=deprecated_parameters,
            deprecation_information=deprecation_information,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error listing user activities: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve user activities",
        )
