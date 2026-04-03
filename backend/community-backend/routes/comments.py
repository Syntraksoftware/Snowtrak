"""Comment routes."""

import logging
import os
import sys

from fastapi import APIRouter, Depends, HTTPException, status

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user
from routes.community_models import (
    CommentCreate,
    CommentUpdate,
    CommentVoteRequest,
    CommentVoteResponse,
    CommunityCommentResponse,
    CommunityDeleteCommentResponse,
)
from routes.validators.community_write_validators import (
    ensure_text_or_media,
    ensure_vote_type,
)
from services.media_validation import normalize_media_urls
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("", response_model=CommunityCommentResponse, status_code=status.HTTP_201_CREATED)
async def create_comment(
    data: CommentCreate,
    user_id: str = Depends(get_current_user),
):
    """Create a new comment."""
    community_client = get_community_client()
    try:
        post_record = community_client.get_post_by_id(data.post_id)
        if not post_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            ) from None

        if data.parent_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "Nested comment threads are disabled. "
                    "Post a top-level comment and mention users with @username."
                ),
            ) from None

        media_urls = normalize_media_urls(data.media_urls)
        body = (data.content or "").strip()
        ensure_text_or_media(
            body,
            media_urls,
            "Comment must include text or at least one media attachment",
        )

        created_comment = community_client.create_comment(
            user_id=user_id,
            post_id=data.post_id,
            content=data.content,
            parent_id=None,
            media_urls=media_urls,
        )
        if not created_comment:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create comment",
            ) from None

        return created_comment
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error creating comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/{comment_id}", response_model=CommunityCommentResponse)
async def get_comment(comment_id: str):
    """Get comment by identifier."""
    community_client = get_community_client()
    try:
        comment_record = community_client.get_comment_by_id(comment_id)
        if not comment_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found",
            ) from None

        return comment_record
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error getting comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.patch("/{comment_id}", response_model=CommunityCommentResponse)
async def update_comment(
    comment_id: str,
    data: CommentUpdate,
    user_id: str = Depends(get_current_user),
):
    """Update a comment owned by the authenticated user."""
    community_client = get_community_client()
    try:
        updated_comment = community_client.update_comment(
            comment_id=comment_id,
            user_id=user_id,
            content=data.content,
        )
        if not updated_comment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or unauthorized",
            ) from None

        return updated_comment
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error updating comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.post("/{comment_id}/vote", response_model=CommentVoteResponse)
async def vote_comment(
    comment_id: str,
    data: CommentVoteRequest,
    user_id: str = Depends(get_current_user),
):
    """Vote on a comment with values -1, 0, or 1."""
    ensure_vote_type(data.vote_type)

    community_client = get_community_client()
    try:
        vote_result = community_client.set_comment_vote(
            comment_id=comment_id,
            user_id=user_id,
            vote_type=data.vote_type,
        )
        if not vote_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or vote operation failed",
            ) from None

        return vote_result
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error voting comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.delete("/{comment_id}", response_model=CommunityDeleteCommentResponse)
async def delete_comment(
    comment_id: str,
    user_id: str = Depends(get_current_user),
):
    """Delete a comment and nested replies."""
    community_client = get_community_client()
    try:
        is_deleted = community_client.delete_comment(comment_id, user_id)
        if not is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or unauthorized",
            ) from None

        return CommunityDeleteCommentResponse(
            message="Comment and nested replies deleted successfully",
            deleted_comment_id=comment_id,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error deleting comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None
