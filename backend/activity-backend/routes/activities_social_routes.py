"""Social and interaction routes for activities."""

import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status

from middleware.auth import get_current_user
from models import (
    CommentCreate,
    CommentResponse,
    CommentsListResponse,
    ShareLinkResponse,
    ToggleKudosResponse,
)
from services.supabase_client import get_activity_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/{activity_id}/kudos", response_model=ToggleKudosResponse)
async def toggle_kudos(
    activity_id: str,
    user_id: str = Depends(get_current_user),
):
    """Like or unlike an activity."""
    activity_client = get_activity_client()
    try:
        kudos_toggle_result = activity_client.toggle_kudos(activity_id, user_id)
        return ToggleKudosResponse(**kudos_toggle_result)
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
):
    """Get comments for an activity."""
    activity_client = get_activity_client()
    try:
        comment_list_response = activity_client.list_comments(
            activity_id, limit=limit, offset=offset
        )
        return CommentsListResponse(
            items=comment_list_response["items"],
            total=comment_list_response["total"],
        )
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
        share_link_result = activity_client.create_share_link(activity_id, user_id)
        return ShareLinkResponse(**share_link_result)
    except Exception as exception:
        logger.error(f"Error creating share link: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None
