"""Comment routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from pydantic import BaseModel
import logging
import sys
import os

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user
from services.supabase_client import get_community_client
from shared import get_request_id

logger = logging.getLogger(__name__)
router = APIRouter()


# Pydantic models
class CommentCreate(BaseModel):
    """Schema for creating a comment."""
    post_id: str
    content: str
    parent_id: Optional[str] = None


class CommentUpdate(BaseModel):
    """Schema for updating a comment."""
    content: str


class VoteRequest(BaseModel):
    """Schema for voting on a comment."""
    vote_type: int  # -1, 0, 1


class VoteResponse(BaseModel):
    """Schema for vote response."""
    comment_id: str
    user_id: str
    vote_value: int
    score: int


class CommentResponse(BaseModel):
    """Schema for comment response."""
    id: str
    user_id: str
    post_id: str
    parent_id: Optional[str] = None
    content: str
    has_parent: bool
    created_at: str
    author_email: Optional[str] = None #TODO: review whether to include email
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None


class DeleteResponse(BaseModel):
    """Schema for delete response."""
    message: str
    deleted_comment_id: Optional[str] = None


@router.post("", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def create_comment(
    data: CommentCreate,
    user_id: str = Depends(get_current_user)
):
    """Create a new comment (authenticated)."""
    try:
        client = get_community_client()
        
        # Verify post exists
        post = client.get_post_by_id(data.post_id)
        if not post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found"
            )
        
        # If parent_id is provided, verify it exists
        if data.parent_id:
            parent = client.get_comment_by_id(data.parent_id)
            if not parent:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Parent comment not found"
                )
        
        result = client.create_comment(
            user_id=user_id,
            post_id=data.post_id,
            content=data.content,
            parent_id=data.parent_id
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create comment"
            )
        
        return result
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error creating comment")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )


@router.get("/{comment_id}", response_model=CommentResponse)
async def get_comment(comment_id: str):
    """Get comment by ID."""
    try:
        client = get_community_client()
        comment = client.get_comment_by_id(comment_id)
        
        if not comment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found"
            )
        
        return comment
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error getting comment")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )


@router.patch("/{comment_id}", response_model=CommentResponse)
async def update_comment(
    comment_id: str,
    data: CommentUpdate,
    user_id: str = Depends(get_current_user),
):
    """Update a comment (authenticated, owner only)."""
    try:
        client = get_community_client()
        updated = client.update_comment(
            comment_id=comment_id,
            user_id=user_id,
            content=data.content,
        )
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or unauthorized",
            )
        return updated
    except HTTPException:
        raise
    except Exception:
        logger.error("Error updating comment")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.post("/{comment_id}/vote", response_model=VoteResponse)
async def vote_comment(
    comment_id: str,
    data: VoteRequest,
    user_id: str = Depends(get_current_user),
):
    """Vote on a comment (authenticated). vote_type: -1, 0, 1."""
    if data.vote_type not in (-1, 0, 1):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="vote_type must be one of: -1, 0, 1",
        )

    try:
        client = get_community_client()
        result = client.set_comment_vote(
            comment_id=comment_id,
            user_id=user_id,
            vote_type=data.vote_type,
        )
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or vote operation failed",
            )
        return result
    except HTTPException:
        raise
    except Exception:
        logger.error("Error voting comment")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.delete("/{comment_id}", response_model=DeleteResponse)
async def delete_comment(
    comment_id: str,
    user_id: str = Depends(get_current_user)
):
    """Delete a comment and all its nested replies (authenticated)."""
    try:
        client = get_community_client()
        
        # The delete method will verify ownership
        success = client.delete_comment(comment_id, user_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or unauthorized"
            )
        
        return DeleteResponse(
            message="Comment and nested replies deleted successfully",
            deleted_comment_id=comment_id
        )
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error deleting comment")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )
