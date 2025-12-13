"""Post routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List
from pydantic import BaseModel
import logging

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


# Pydantic models
class PostCreate(BaseModel):
    """Schema for creating a post."""
    subthread_id: str
    title: str
    content: str


class PostResponse(BaseModel):
    """Schema for post response."""
    post_id: str
    user_id: str
    subthread_id: str
    title: str
    content: str
    created_at: str
    author_email: Optional[str] = None
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None


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


class CommentsListResponse(BaseModel):
    """Schema for comments list response."""
    comments: List[CommentResponse]
    total: int
    post_id: str


class DeleteResponse(BaseModel):
    """Schema for delete response."""
    message: str
    deleted_post_id: Optional[str] = None


@router.post("", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    data: PostCreate,
    user_id: str = Depends(get_current_user)
):
    """Create a new post (authenticated)."""
    try:
        client = get_community_client()
        
        # Verify subthread exists
        subthread = client.get_subthread_by_id(data.subthread_id)
        if not subthread:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found"
            )
        
        result = client.create_post(
            user_id=user_id,
            subthread_id=data.subthread_id,
            title=data.title,
            content=data.content
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create post"
            )
        
        return result
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error creating post")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )


@router.get("/{post_id}", response_model=PostResponse)
async def get_post(post_id: str):
    """Get post by ID."""
    try:
        client = get_community_client()
        post = client.get_post_by_id(post_id)
        
        if not post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found"
            )
        
        return post
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting post: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{post_id}/comments", response_model=CommentsListResponse)
async def list_post_comments(post_id: str):
    """List all comments for a post."""
    try:
        client = get_community_client()
        
        # Verify post exists
        post = client.get_post_by_id(post_id)
        if not post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found"
            )
        
        comments = client.list_comments_by_post(post_id)
        total = client.count_comments_by_post(post_id)
        
        # Convert dicts to Pydantic models
        comment_models = [CommentResponse(**comment) for comment in comments]
        
        return CommentsListResponse(
            comments=comment_models,
            total=total,
            post_id=post_id
        )
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error listing post comments")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )


@router.delete("/{post_id}", response_model=DeleteResponse)
async def delete_post(
    post_id: str,
    user_id: str = Depends(get_current_user)
):
    """Delete a post and all its comments (authenticated)."""
    try:
        client = get_community_client()
        
        # The delete method will verify ownership
        success = client.delete_post(post_id, user_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found or unauthorized"
            )
        
        return DeleteResponse(
            message="Post and all comments deleted successfully",
            deleted_post_id=post_id
        )
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error deleting post")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )
