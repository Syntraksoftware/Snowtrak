"""Read-oriented post routes."""
import logging
import os
import sys
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_optional_user
from routes.community_models import CommunityCommentResponse, CommunityPostResponse
from routes.list_response_builder import build_paginated_list_response
from services.supabase_client import get_community_client
from shared import ListResponse

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/{post_id}", response_model=CommunityPostResponse)
async def get_post(post_id: str):
    """Get post by identifier."""
    community_client = get_community_client()
    try:
        post_record = community_client.get_post_by_id(post_id)
        if not post_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )

        return post_record
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error getting post: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.get("/user/{user_id}", response_model=ListResponse)
async def list_posts_by_user(
    request: Request,
    user_id: str,
    limit: int = Query(20, ge=1, le=100), # le: max limit allowed 
    offset: int = Query(0, ge=0),
    current_user: Optional[str] = Depends(get_optional_user),
):
    """List posts by user identifier."""
    community_client = get_community_client()
    try:
        post_records = community_client.list_posts_by_user_id(
            user_id=user_id,
            limit=limit,
            offset=offset,
        )
        total_records = len(post_records)
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
        logger.error(f"Error listing posts by user: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.get("/{post_id}/comments", response_model=ListResponse)
async def list_post_comments(request: Request, post_id: str):
    """List comments for a post."""
    community_client = get_community_client()
    try:
        post_record = community_client.get_post_by_id(post_id)
        if not post_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )

        comment_records = community_client.list_comments_by_post(post_id)
        total_records = community_client.count_comments_by_post(post_id)
        comment_items = [
            CommunityCommentResponse(**comment_record)
            for comment_record in comment_records
        ]

        return build_paginated_list_response(
            request=request,
            items=comment_items,
            limit=max(1, len(comment_items)),
            offset=0,
            total=total_records,
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error listing post comments: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )
