"""Read-oriented post routes."""

import logging
import os
import sys
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared import ListResponse

from middleware.auth import get_optional_user
from routes.community_models import (
    CommentsBatchRequest,
    CommentsBatchResponse,
    CommunityCommentResponse,
    CommunityPostResponse,
    PostCommentsBundle,
)
from routes.list_response_builder import build_paginated_list_response
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()

_MAX_COMMENTS_BATCH = 50


def _dedupe_post_ids(raw: list[str]) -> list[str]:
    ordered: list[str] = []
    for item in raw:
        key = (item or "").strip()
        if key and key not in ordered:
            ordered.append(key)
    return ordered


@router.post("/comments/batch", response_model=CommentsBatchResponse)
async def batch_post_comments(
    data: CommentsBatchRequest,
    current_user: str | None = Depends(get_optional_user),
):
    """
    Load comments for many posts in one round trip (Supabase single `in` filter).

    Reduces N+1 HTTP calls from the mobile/web client when rendering a feed.
    """
    ordered = _dedupe_post_ids(data.post_ids)
    if len(ordered) > _MAX_COMMENTS_BATCH:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"At most {_MAX_COMMENTS_BATCH} distinct post_ids per batch",
        ) from None

    community_client = get_community_client()
    try:
        by_post = community_client.list_comments_by_post_ids(
            ordered,
            current_user_id=current_user,
        )
        items = [
            PostCommentsBundle(
                post_id=pid,
                comments=[CommunityCommentResponse(**row) for row in by_post.get(pid, [])],
            )
            for pid in ordered
        ]
        return CommentsBatchResponse(items=items)
    except HTTPException:
        raise
    except Exception as exception:
        logger.error("Error in batch_post_comments: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


def list_feed_posts(
    request: Request,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: str | None = Depends(get_optional_user),
):
    """Global feed: all posts across subthreads, newest first.

    NOTE: This function is registered directly in main.py at GET /api/v1/feed
    (not via the posts router) to avoid routing precedence issues with /{post_id}.
    """
    community_client = get_community_client()
    try:
        post_records = community_client.list_recent_posts(
            limit=limit,
            offset=offset,
            current_user_id=current_user,
        )
        total_records = community_client.count_all_posts()
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
        logger.error("Error listing feed posts: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/{post_id}", response_model=CommunityPostResponse)
async def get_post(post_id: UUID):
    """Get post by identifier."""
    community_client = get_community_client()
    try:
        post_record = community_client.get_post_by_id(str(post_id))
        if not post_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            ) from None

        return post_record
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error getting post: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        ) from None


@router.get("/user/{user_id}", response_model=ListResponse)
async def list_posts_by_user(
    request: Request,
    user_id: str,
    limit: int = Query(20, ge=1, le=100),  # le: max limit allowed
    offset: int = Query(0, ge=0),
    current_user: str | None = Depends(get_optional_user),
):
    """List posts by user identifier."""
    community_client = get_community_client()
    try:
        post_records = community_client.list_posts_by_user_id(
            user_id=user_id,
            limit=limit,
            offset=offset,
            current_user_id=current_user,
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
        ) from None


@router.get("/{post_id}/comments", response_model=ListResponse)
async def list_post_comments(
    request: Request,
    post_id: UUID,
    current_user: str | None = Depends(get_optional_user),
):
    """List comments for a post."""
    community_client = get_community_client()
    pid = str(post_id)
    try:
        post_record = community_client.get_post_by_id(pid)
        if not post_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            ) from None

        comment_records = community_client.list_comments_by_post(
            pid,
            current_user_id=current_user,
        )
        total_records = community_client.count_comments_by_post(pid)
        comment_items = [
            CommunityCommentResponse(**comment_record) for comment_record in comment_records
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
        ) from None


@router.get("/{post_id}/conversation", response_model=ListResponse)
async def get_post_conversation(request: Request, post_id: UUID):
    """
    Flattened conversation for one thread (chronological), same payload as
    ``/{post_id}/comments`` — alias for Threads-style ``conversation`` naming.
    """
    return await list_post_comments(request, post_id)
