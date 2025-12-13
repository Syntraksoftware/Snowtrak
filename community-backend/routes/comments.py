"""Comment routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from pydantic import BaseModel
import logging

from middleware.auth import get_current_user
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


# Pydantic models
class CommentCreate(BaseModel):
    """Schema for creating a comment."""
    post_id: str
    content: str
    parent_id: Optional[str] = None


class CommentResponse(BaseModel):
    """Schema for comment response."""
    id: str
    user_id: str
    post_id: str
    parent_id: Optional[str] = None
    content: str
    has_parent: bool
    created_at: str
    author_email: Optional[str] = None
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
    except Exception as e:
        logger.error(f"Error creating comment: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
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
    except Exception as e:
        logger.error(f"Error getting comment: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
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
    except Exception as e:
        logger.error(f"Error deleting comment: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
