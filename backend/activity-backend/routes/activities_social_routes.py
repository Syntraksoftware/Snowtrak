"""Social and interaction routes for activities."""

import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
from shared.visibility import can_view

from middleware.auth import get_current_user, get_optional_user
from models import (
    CommentCreate,
    CommentResponse,
    CommentsListResponse,
    ShareLinkResponse,
    ToggleKudosResponse,
)
from services.offload import offload
from services.supabase_client import get_activity_client

logger = logging.getLogger(__name__)
router = APIRouter()


async def _require_visible(activity_id: str, viewer_id: str | None) -> dict:
    """Fetch an activity, or 404 if this viewer may not see it.

    404 rather than 403: a private activity's existence is itself private, so
    "hidden" and "does not exist" must be indistinguishable to the caller.

    Args:
        activity_id: The activity the caller is reacting to or reading.
        viewer_id: The caller, or `None` for an anonymous request.

    Returns:
        The activity row, once visibility is confirmed.

    Raises:
        HTTPException: 404 if the activity is missing or not visible to
            `viewer_id`.
    """
    client = get_activity_client()
    if viewer_id:
        # The follow graph lookup doesn't depend on the activity row, so run
        # both blocking Supabase calls concurrently; both stay inside
        # offload() so neither one stalls the event loop.
        record, following = await asyncio.gather(
            offload(client.get_activity_by_id, activity_id),
            offload(client.following_ids, viewer_id),
        )
    else:
        record, following = await offload(client.get_activity_by_id, activity_id), []
    if record is None or not can_view(record, viewer_id, following):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found",
        ) from None
    return record


@router.post("/{activity_id}/kudos", response_model=ToggleKudosResponse)
async def toggle_kudos(
    activity_id: str,
    user_id: str = Depends(get_current_user),
):
    """Like or unlike an activity."""
    activity_client = get_activity_client()
    try:
        await _require_visible(activity_id, user_id)
        kudos_toggle_result = activity_client.toggle_kudos(activity_id, user_id)
        return ToggleKudosResponse(**kudos_toggle_result)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error toggling kudos: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/{activity_id}/comments", response_model=CommentsListResponse)
async def list_comments(
    activity_id: str,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    viewer_id: str | None = Depends(get_optional_user),
):
    """Get comments for an activity."""
    activity_client = get_activity_client()
    try:
        await _require_visible(activity_id, viewer_id)
        comment_list_response = activity_client.list_comments(
            activity_id, limit=limit, offset=offset
        )
        return CommentsListResponse(
            items=comment_list_response["items"],
            total=comment_list_response["total"],
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error listing activity comments: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.post(
    "/{activity_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED
)
async def add_comment(
    activity_id: str,
    data: CommentCreate,
    user_id: str = Depends(get_current_user),
):
    """Add a comment to an activity."""
    activity_client = get_activity_client()
    try:
        await _require_visible(activity_id, user_id)
        created_comment = activity_client.add_comment(activity_id, user_id, data.content)
        if not created_comment:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add comment",
            ) from None
        return created_comment
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error adding comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.post("/{activity_id}/share", response_model=ShareLinkResponse)
async def create_share_link(
    activity_id: str,
    user_id: str = Depends(get_current_user),
):
    """Generate a shareable link for an activity."""
    activity_client = get_activity_client()
    try:
        await _require_visible(activity_id, user_id)
        share_link_result = activity_client.create_share_link(activity_id, user_id)
        return ShareLinkResponse(**share_link_result)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error creating share link: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None
