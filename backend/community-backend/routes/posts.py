"""Post routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from typing import Optional, List
from pydantic import BaseModel
import logging
import sys
import os

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_community_client
from shared import ListResponse, ListMeta, PaginationMeta, get_request_id

logger = logging.getLogger(__name__)
router = APIRouter()


# Pydantic models
class PostCreate(BaseModel):
    """Schema for creating a post."""
    subthread_id: str
    title: str
    content: str


class PostUpdate(BaseModel):
    """Schema for updating a post."""
    title: Optional[str] = None
    content: Optional[str] = None


class VoteRequest(BaseModel):
    """Schema for voting on a post."""
    vote_type: int  # -1, 0, 1


class VoteResponse(BaseModel):
    """Schema for vote response."""
    post_id: str
    user_id: str
    vote_value: int
    score: int


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


@router.patch("/{post_id}", response_model=PostResponse)
async def update_post(
    post_id: str,
    data: PostUpdate,
    user_id: str = Depends(get_current_user),
):
    """Update a post (authenticated, owner only)."""
    try:
        client = get_community_client()
        updated = client.update_post(
            post_id=post_id,
            user_id=user_id,
            title=data.title,
            content=data.content,
        )
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found or unauthorized",
            )
        return updated
    except HTTPException:
        raise
    except Exception:
        logger.error("Error updating post")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.post("/{post_id}/vote", response_model=VoteResponse)
async def vote_post(
    post_id: str,
    data: VoteRequest,
    user_id: str = Depends(get_current_user),
):
    """Vote on a post (authenticated). vote_type: -1, 0, 1."""
    if data.vote_type not in (-1, 0, 1):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="vote_type must be one of: -1, 0, 1",
        )

    try:
        client = get_community_client()
        result = client.set_post_vote(
            post_id=post_id,
            user_id=user_id,
            vote_type=data.vote_type,
        )
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found or vote operation failed",
            )
        return result
    except HTTPException:
        raise
    except Exception:
        logger.error("Error voting post")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.get("/user/{user_id}", response_model=ListResponse)
async def list_posts_by_user(
    request: Request,
    user_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: Optional[str] = Depends(get_optional_user)
):
    """List posts by user ID (optional authentication)."""
    try:
        client = get_community_client()

        post_records = client.list_posts_by_user_id(
            user_id=user_id,
            limit=limit,
            offset=offset
        )
        total_records = len(post_records)
        post_models = [PostResponse(**post_record) for post_record in post_records]

        request_id = get_request_id(request)
        pagination_metadata = PaginationMeta(
            limit=limit,
            offset=offset,
            total=total_records,
            next_cursor=None,
            has_next=offset + limit < total_records,
        )
        response_metadata = ListMeta(
            request_id=request_id,
            pagination=pagination_metadata,
        )

        return ListResponse(items=post_models, meta=response_metadata)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error listing posts by user: {str(exception)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )


@router.get("/{post_id}/comments", response_model=ListResponse)
async def list_post_comments(
    request: Request,
    post_id: str,
):
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
        
        comment_records = client.list_comments_by_post(post_id)
        total_records = client.count_comments_by_post(post_id)
        comment_models = [CommentResponse(**comment_record) for comment_record in comment_records]

        request_id = get_request_id(request)
        pagination_metadata = PaginationMeta(
            limit=len(comment_records),
            offset=0,
            total=total_records,
            next_cursor=None,
            has_next=False,
        )
        response_metadata = ListMeta(
            request_id=request_id,
            pagination=pagination_metadata,
        )

        return ListResponse(items=comment_models, meta=response_metadata)
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
