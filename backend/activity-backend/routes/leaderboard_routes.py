"""Leaderboard reads.

The board shows a name, a total and a rank. It never links to an activity,
which is what lets an activity with `private` visibility count towards a
total without leaking anything about itself.
"""

import logging
from datetime import UTC, date, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status

from domain.competition.metrics import Metric, week_start
from middleware.auth import get_current_user
from routes.competition_models import (
    LeaderboardEntry,
    LeaderboardPlacing,
    LeaderboardResponse,
)
from services.leaderboard_operations import (
    DEFAULT_LIMIT,
    FRIENDS_SCOPE,
    GLOBAL_SCOPE,
    MAX_LIMIT,
    get_leaderboard_operations,
)
from services.offload import offload

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/leaderboard", tags=["leaderboard"])


def _scope(value: str) -> str:
    """Validates a scope.

    Args:
        value: `'global'`, `'friends'`, or an ISO 3166-1 alpha-2 code.

    Returns:
        The scope, upper-cased when it is a country.

    Raises:
        HTTPException: 422 if it is none of those.
    """
    if value in (GLOBAL_SCOPE, FRIENDS_SCOPE):
        return value
    if len(value) == 2 and value.isalpha():
        return value.upper()
    raise HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail="scope must be 'global', 'friends' or a two-letter country code",
    )


@router.get("/me", response_model=LeaderboardPlacing)
async def my_placing(
    metric: Metric = Query(Metric.VERTICAL),
    scope: str = Query(GLOBAL_SCOPE),
    user_id: str = Depends(get_current_user),
):
    """Where the caller stands this week.

    Separate from the board because someone in eight-thousandth place still
    has to see their own position, and paging to it is not an option.
    """
    resolved = _scope(scope)
    operations = get_leaderboard_operations()
    placing = await offload(operations.placing, user_id, metric, resolved)
    return LeaderboardPlacing(
        metric=metric,
        scope=resolved,
        week_start=week_start(datetime.now(UTC)).isoformat(),
        rank=placing["rank"] if placing else None,
        value=placing["value"] if placing else 0.0,
    )


@router.get("/weeks/{week}", response_model=LeaderboardResponse)
async def settled_week(
    week: date,
    metric: Metric = Query(Metric.VERTICAL),
    scope: str = Query(GLOBAL_SCOPE),
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT),
    _: str = Depends(get_current_user),
):
    """A finished week, read back from the snapshot.

    Empty for a week that was never settled, which includes every week
    before this feature shipped.
    """
    resolved = _scope(scope)
    operations = get_leaderboard_operations()
    rows = await offload(operations.week, week, metric, resolved, limit)
    return LeaderboardResponse(
        metric=metric,
        scope=resolved,
        week_start=week.isoformat(),
        settled=True,
        entries=[LeaderboardEntry(**row) for row in rows],
    )


@router.get("", response_model=LeaderboardResponse)
async def current_board(
    metric: Metric = Query(Metric.VERTICAL),
    scope: str = Query(GLOBAL_SCOPE),
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT),
    user_id: str = Depends(get_current_user),
):
    """This week's live board, best first.

    `scope=friends` ranks the caller against the people they mutually
    follow. That is the board the Challenge button lives on, because a duel
    needs a mutual follow to be offered at all.
    """
    resolved = _scope(scope)
    operations = get_leaderboard_operations()
    rows = await offload(operations.top, metric, resolved, None, limit, user_id)
    return LeaderboardResponse(
        metric=metric,
        scope=resolved,
        week_start=week_start(datetime.now(UTC)).isoformat(),
        settled=False,
        entries=[LeaderboardEntry(**row) for row in rows],
    )
