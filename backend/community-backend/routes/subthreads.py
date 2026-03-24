"""Subthread routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from typing import Optional, List, Union
from pydantic import BaseModel
import logging
import sys
import os

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user, get_optional_user
from services.supabase_client import get_community_client
from shared import ListResponse, ListMeta, PaginationMeta, ResponseMeta, get_request_id

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


@router.get("", response_model=Union[ListResponse, SubthreadsListResponse])
async def list_subthreads(
    request: Request,
    limit: int = Query(50, ge=1, le=200),
    format: Optional[str] = Query(None, description="Response format: 'standard' for {items, meta} or 'legacy' for {subthreads, total}")
):
    """
    List all subthreads.
    
    Supports both new standardized format and legacy response format.
    Default is new standardized format for new clients.
    """
    try:
        client = get_community_client()
        subthreads = client.list_subthreads(limit=limit)
        
        # Convert dicts to Pydantic models
        subthread_models = [SubthreadResponse(**sub) for sub in subthreads]
        
        # Support legacy format for backward compatibility
        if format == "legacy":
            return SubthreadsListResponse(
                subthreads=subthread_models,
                total=len(subthread_models)
            )
        
        # Return standardized list response
        request_id = get_request_id(request)
        total = len(subthread_models)
        pagination_meta = PaginationMeta(
            limit=limit,
            offset=0,
            total=total,
            next_cursor=None,
            has_next=False,
        )
        response_meta = ListMeta(
            request_id=request_id,
            pagination=pagination_meta,
        )
        
        return ListResponse(items=subthread_models, meta=response_meta)
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


@router.get("/{subthread_id}/posts", response_model=Union[ListResponse, PostsListResponse])
async def list_subthread_posts(
    request: Request,
    subthread_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    format: Optional[str] = Query(None, description="Response format: 'standard' for {items, meta} or 'legacy' for {posts, total, page, page_size}")
):
    """
    List posts in a subthread.
    
    Supports both new standardized format and legacy response format.
    Default is new standardized format for new clients.
    """
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
        
        # Support legacy format for backward compatibility
        if format == "legacy":
            return PostsListResponse(
                posts=post_models,
                total=total,
                page=offset // limit + 1,
                page_size=limit
            )
        
        # Return standardized list response
        request_id = get_request_id(request)
        pagination_meta = PaginationMeta(
            limit=limit,
            offset=offset,
            total=total,
            next_cursor=None,
            has_next=offset + limit < total,
        )
        response_meta = ListMeta(
            request_id=request_id,
            pagination=pagination_meta,
        )
        
        return ListResponse(items=post_models, meta=response_meta)
    except HTTPException:
        raise
    except Exception:
        logger.error(f"Error listing subthread posts")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
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
        
        # TODO: Implement admin/moderator check before production  
        # TEMPORARY: Block all deletions until authorization is implemented  
        
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
        logger.error(f"Error deleting subthread")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error"
        )
