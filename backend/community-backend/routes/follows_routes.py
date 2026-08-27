"""Follow-graph routes.

`/api/v1/follows` is its own domain, owned by community-backend. It does not
live under `/api/v1/users` because that belongs to main-backend, and
docs/service-ownership.md allows exactly one owner per domain.
"""

import logging
import os
import sys
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared import ListResponse

from config import get_config
from middleware.auth import get_current_user, get_optional_user
from routes.community_models import FollowStatsResponse, FollowUserResponse
from routes.list_response_builder import build_paginated_list_response
from services.community_cache import (
    follow_stats_cache_key,
    get_cache_version,
    get_cached_json,
    invalidate_follow_stats_cache,
    set_cached_json,
)
from services.offload import offload
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


# Registered before /{user_id} on purpose: a two-segment path would otherwise
# be shadowed. posts_read_routes.py carries the same warning about /{post_id}.
@router.delete("/me/followers/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_follower(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Drop somebody who follows you.

    The escape hatch that makes open following bearable: the same edge delete
    as unfollow, with the pair reversed.
    """
    await offload(get_community_client().unfollow, str(user_id), current_user)
    await invalidate_follow_stats_cache()


@router.post("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def follow_user(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Follow somebody. Idempotent."""
    if str(user_id) == current_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot follow yourself",
        ) from None

    if not await offload(get_community_client().follow, current_user, str(user_id)):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not follow this user",
        ) from None
    await invalidate_follow_stats_cache()


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unfollow_user(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Unfollow somebody. Succeeds even if you were not following them."""
    await offload(get_community_client().unfollow, current_user, str(user_id))
    await invalidate_follow_stats_cache()


@router.get("/{user_id}/stats", response_model=FollowStatsResponse)
async def follow_stats(
    user_id: UUID,
    current_user: str | None = Depends(get_optional_user),
):
    """Counts plus this viewer's relationship, in one call for a profile header.

    Cached, because this is on the path of every profile open and the database
    is ~440ms away. A follow or unfollow invalidates it, so your own action
    still shows up immediately.
    """
    target = str(user_id)
    version = await get_cache_version("follow-stats")
    cache_key = follow_stats_cache_key(target, current_user, version)

    cached = await get_cached_json(cache_key)
    if isinstance(cached, dict):
        return FollowStatsResponse(**cached)

    snapshot = await offload(get_community_client().follow_snapshot, target, current_user)
    await set_cached_json(
        cache_key,
        snapshot,
        get_config().CACHE_FOLLOW_STATS_TTL_SECONDS,
    )
    return FollowStatsResponse(**snapshot)


@router.get("/{user_id}/followers", response_model=ListResponse)
async def list_followers(
    request: Request,
    user_id: UUID,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """People who follow this user, newest first."""
    return _edge_page(
        request=request,
        user_id=str(user_id),
        direction="followers",
        limit=limit,
        offset=offset,
    )


@router.get("/{user_id}/following", response_model=ListResponse)
async def list_following(
    request: Request,
    user_id: UUID,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """People this user follows, newest first."""
    return _edge_page(
        request=request,
        user_id=str(user_id),
        direction="following",
        limit=limit,
        offset=offset,
    )


def _edge_page(
    *,
    request: Request,
    user_id: str,
    direction: str,
    limit: int,
    offset: int,
) -> ListResponse:
    client = get_community_client()
    rows = client.list_follow_edges(
        user_id=user_id,
        direction=direction,
        limit=limit,
        offset=offset,
    )
    total = (
        client.count_followers(user_id)
        if direction == "followers"
        else client.count_following(user_id)
    )
    return build_paginated_list_response(
        request=request,
        items=[FollowUserResponse(**row) for row in rows],
        limit=limit,
        offset=offset,
        total=total,
    )
