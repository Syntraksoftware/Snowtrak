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
            )

        if data.parent_id:
            parent_comment = community_client.get_comment_by_id(data.parent_id)
            if not parent_comment:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Parent comment not found",
                )

        created_comment = community_client.create_comment(
            user_id=user_id,
            post_id=data.post_id,
            content=data.content,
            parent_id=data.parent_id,
        )
        if not created_comment:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create comment",
            )

        return created_comment
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error creating comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


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
            )

        return comment_record
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error getting comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


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
            )

        return updated_comment
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error updating comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.post("/{comment_id}/vote", response_model=CommentVoteResponse)
async def vote_comment(
    comment_id: str,
    data: CommentVoteRequest,
    user_id: str = Depends(get_current_user),
):
    """Vote on a comment with values -1, 0, or 1."""
    if data.vote_type not in (-1, 0, 1):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="vote_type must be one of: -1, 0, 1",
        )

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
            )

        return vote_result
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error voting comment: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


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
            )

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
        )
