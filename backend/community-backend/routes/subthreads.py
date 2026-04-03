"""Subthread routes."""

import logging
import os
import sys

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared import ListResponse

from middleware.auth import get_current_user
from routes.community_models import (
    CommunityPostResponse,
    CommunitySubthreadDeleteResponse,
    CommunitySubthreadResponse,
    SubthreadCreate,
)
from routes.list_response_builder import build_paginated_list_response
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("", response_model=ListResponse)
async def list_subthreads(
    request: Request,
    limit: int = Query(50, ge=1, le=200),
):
    """List all subthreads."""
    community_client = get_community_client()
    try:
        subthread_records = community_client.list_subthreads(limit=limit)
        subthread_items = [
            CommunitySubthreadResponse(**subthread_record) for subthread_record in subthread_records
        ]

        return build_paginated_list_response(
            request=request,
            items=subthread_items,
            limit=limit,
            offset=0,
            total=len(subthread_items),
        )
    except Exception as exception:
        logger.error(f"Error listing subthreads: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.post("", response_model=CommunitySubthreadResponse, status_code=status.HTTP_201_CREATED)
async def create_subthread(
    data: SubthreadCreate,
    user_id: str = Depends(get_current_user),
):
    """Create a new subthread."""
    community_client = get_community_client()
    try:
        created_subthread = community_client.create_subthread(
            name=data.name,
            description=data.description,
        )
        if not created_subthread:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create subthread",
            ) from None

        return created_subthread
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error creating subthread: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/{subthread_id}", response_model=CommunitySubthreadResponse)
async def get_subthread(subthread_id: str):
    """Get subthread by identifier."""
    community_client = get_community_client()
    try:
        subthread_record = community_client.get_subthread_by_id(subthread_id)
        if not subthread_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found",
            ) from None

        return subthread_record
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error getting subthread: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/{subthread_id}/posts", response_model=ListResponse)
async def list_subthread_posts(
    request: Request,
    subthread_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """List posts inside a subthread."""
    community_client = get_community_client()
    try:
        subthread_record = community_client.get_subthread_by_id(subthread_id)
        if not subthread_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found",
            ) from None

        post_records = community_client.list_posts_by_subthread(
            subthread_id=subthread_id,
            limit=limit,
            offset=offset,
        )
        total_records = community_client.count_posts_by_subthread(subthread_id)
        post_items = [CommunityPostResponse(**post_record) for post_record in post_records]

        return build_paginated_list_response(
            request=request,
            items=post_items,
            limit=limit,
            offset=offset,
            total=total_records,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error listing subthread posts: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.delete("/{subthread_id}", response_model=CommunitySubthreadDeleteResponse)
async def delete_subthread(
    subthread_id: str,
    user_id: str = Depends(get_current_user),
):
    """Delete a subthread and nested content."""
    community_client = get_community_client()
    try:
        is_deleted = community_client.delete_subthread(subthread_id)
        if not is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found",
            ) from None

        return CommunitySubthreadDeleteResponse(
            message="Subthread, posts, and comments deleted successfully",
            deleted_subthread_id=subthread_id,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error deleting subthread: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None
