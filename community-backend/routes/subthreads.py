"""Subthread routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List
from pydantic import BaseModel
import logging

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


# Pydantic models
class SubthreadCreate(BaseModel):
    """Schema for creating a subthread."""
    name: str
    description: Optional[str] = None


class SubthreadResponse(BaseModel):
    """Schema for subthread response."""
    id: str
    name: str
    description: Optional[str] = None
    created_at: str


class SubthreadsListResponse(BaseModel):
    """Schema for subthreads list response."""
    subthreads: List[SubthreadResponse]
    total: int


@router.get("", response_model=SubthreadsListResponse)
async def list_subthreads(limit: int = Query(50, ge=1, le=200)):
    """List all subthreads."""
    try:
        client = get_community_client()
        subthreads = client.list_subthreads(limit=limit)
        
        # Convert dicts to Pydantic models
        subthread_models = [SubthreadResponse(**sub) for sub in subthreads]
        
        return SubthreadsListResponse(
            subthreads=subthread_models,
            total=len(subthread_models)
        )
    except Exception as e:
        logger.error(f"Error listing subthreads: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("", response_model=SubthreadResponse, status_code=status.HTTP_201_CREATED)
async def create_subthread(
    data: SubthreadCreate,
    user_id: str = Depends(get_current_user)
):
    """Create a new subthread (authenticated)."""
    try:
        client = get_community_client()
        result = client.create_subthread(
            name=data.name,
            description=data.description
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create subthread"
            )
        
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating subthread: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{subthread_id}", response_model=SubthreadResponse)
async def get_subthread(subthread_id: str):
    """Get subthread by ID."""
    try:
        client = get_community_client()
        subthread = client.get_subthread_by_id(subthread_id)
        
        if not subthread:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found"
            )
        
        return subthread
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting subthread: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


class PostResponse(BaseModel):
    """Schema for post in subthread list."""
    post_id: str
    user_id: str
    subthread_id: str
    title: str
    content: str
    created_at: str
    author_email: Optional[str] = None
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None


class PostsListResponse(BaseModel):
    """Schema for posts list response."""
    posts: List[PostResponse]
    total: int
    page: int
    page_size: int


@router.get("/{subthread_id}/posts", response_model=PostsListResponse)
async def list_subthread_posts(
    subthread_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """List posts in a subthread."""
    try:
        client = get_community_client()
        
        # Verify subthread exists
        subthread = client.get_subthread_by_id(subthread_id)
        if not subthread:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found"
            )
        
        posts = client.list_posts_by_subthread(
            subthread_id=subthread_id,
            limit=limit,
            offset=offset
        )
        total = client.count_posts_by_subthread(subthread_id)
        
        # Convert dicts to Pydantic models
        post_models = [PostResponse(**post) for post in posts]
        
        return PostsListResponse(
            posts=post_models,
            total=total,
            page=offset // limit + 1,
            page_size=limit
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing subthread posts: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


class DeleteResponse(BaseModel):
    """Schema for delete response."""
    message: str
    deleted_subthread_id: Optional[str] = None


@router.delete("/{subthread_id}", response_model=DeleteResponse)
async def delete_subthread(
    subthread_id: str,
    user_id: str = Depends(get_current_user)
):
    """Delete a subthread and all its posts/comments (authenticated)."""
    try:
        client = get_community_client()
        
        # Note: In production, add admin/moderator check here
        # For now, any authenticated user can delete
        
        success = client.delete_subthread(subthread_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found"
            )
        
        return DeleteResponse(
            message="Subthread, posts, and comments deleted successfully",
            deleted_subthread_id=subthread_id
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting subthread: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
