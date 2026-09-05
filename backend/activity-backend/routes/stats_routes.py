"""Stats route: GET /me/stats returns cached user aggregates."""

import logging
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, status

from middleware.auth import get_current_user
from models import UserStatsResponse
from services.user_stats_service import get_stats_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/me/stats", response_model=UserStatsResponse)
async def get_my_stats(user_id: str = Depends(get_current_user)):
    """Return the authenticated user's stats, recomputing on a cache miss.

    A missing row in `user_stats` means nobody has written one yet — it does
    not mean the user has no activities. `recompute_and_upsert` only fires on
    activity create/update/delete and pipeline completion, so an account
    seeded straight into `activities` (bypassing those paths) has real
    activities and no cached row. A cache miss recomputes from the activities
    table and persists the result, self-healing that account on this request.
    A user with genuinely no activities gets a persisted zeros row from
    the recompute, so the in-route zero fallback below only fires when
    the recompute itself fails (e.g. the DB is unreachable).
    """
    stats_service = get_stats_service()
    stats = stats_service.get_stats(user_id)

    if stats is None:
        stats = stats_service.recompute_and_upsert(user_id)

    if stats is None:
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
        return UserStatsResponse(
            user_id=user_id,
            week_start=week_start.isoformat(),
            weekly_distance_km=0,
            weekly_time_min=0,
            weekly_elev_gain_m=0,
            weekly_session_count=0,
            last_week_session_count=0,
            yearly_distance_km=0,
            yearly_time_min=0,
            yearly_elev_gain_m=0,
            yearly_session_count=0,
            all_time_distance_km=0,
            all_time_time_min=0,
            all_time_elev_gain_m=0,
            all_time_session_count=0,
            current_streak_weeks=0,
            longest_streak_weeks=0,
            activity_days=[],
            best_efforts=[],
        )

    try:
        return UserStatsResponse(**stats)
    except Exception:
        logger.exception("Failed to serialize stats for user %s", user_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve stats",
        ) from None
