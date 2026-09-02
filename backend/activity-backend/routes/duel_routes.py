"""Duel routes.

Eligibility, legality and settlement are decided in the domain and enforced
again as conditions on each update. These handlers translate between HTTP
and that, and do nothing else.
"""

import logging
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status

from domain.competition.duel import Duel, DuelStatus
from middleware.auth import get_current_user
from routes.competition_models import (
    DuelCreate,
    DuelResponse,
    DuelsListResponse,
)
from services.duel_operations import (
    DEFAULT_LIMIT,
    MAX_LIMIT,
    DuelInProgress,
    NotEligible,
    get_duel_operations,
)
from services.offload import offload

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/duels", tags=["duels"])


def _response(duel: Duel) -> DuelResponse:
    return DuelResponse(
        id=duel.id,
        challenger_id=duel.challenger_id,
        opponent_id=duel.opponent_id,
        metric=duel.metric,
        duration=duel.duration,
        status=duel.status,
        created_at=duel.created_at.isoformat(),
        starts_at=duel.starts_at.isoformat() if duel.starts_at else None,
        ends_at=duel.ends_at.isoformat() if duel.ends_at else None,
        challenger_value=duel.challenger_value,
        opponent_value=duel.opponent_value,
        winner_id=duel.winner_id,
        settled_at=duel.settled_at.isoformat() if duel.settled_at else None,
    )


async def _visible_duel(duel_id: str, viewer_id: str) -> Duel:
    """Loads a duel the caller is a player in.

    404 rather than 403 for someone else's duel: who is challenging whom is
    not a stranger's business, so "not yours" and "does not exist" look the
    same from outside.

    Raises:
        HTTPException: 404 if it is missing or not the caller's.
    """
    duel = await offload(get_duel_operations().get, duel_id)
    if duel is None or not duel.involves(viewer_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Duel not found")
    return duel


@router.post("", response_model=DuelResponse, status_code=status.HTTP_201_CREATED)
async def create_duel(payload: DuelCreate, user_id: str = Depends(get_current_user)):
    """Challenges someone who follows you back.

    Raises:
        HTTPException: 403 when the two do not follow each other, 409 when a
            duel between them already stands, 422 for a self-challenge.
    """
    if payload.opponent_id == user_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="You cannot duel yourself",
        )
    try:
        duel = await offload(
            get_duel_operations().create,
            user_id,
            payload.opponent_id,
            payload.metric,
            payload.duration,
        )
    except NotEligible:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only duel someone who follows you back",
        ) from None
    except DuelInProgress:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A duel between you two is already under way",
        ) from None
    return _response(duel)


@router.get("", response_model=DuelsListResponse)
async def list_duels(
    duel_status: DuelStatus | None = Query(None, alias="status"),
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT),
    offset: int = Query(0, ge=0),
    user_id: str = Depends(get_current_user),
):
    """The caller's duels, newest first."""
    duels = await offload(get_duel_operations().list_for, user_id, duel_status, limit, offset)
    items = [_response(duel) for duel in duels]
    return DuelsListResponse(items=items, total=len(items))


@router.get("/{duel_id}", response_model=DuelResponse)
async def get_duel(duel_id: str, user_id: str = Depends(get_current_user)):
    """One duel, settled on the spot if its window has closed.

    The background sweep would get to it within five minutes, but a player
    opening a finished duel should see the result rather than a countdown
    that has already run out.
    """
    duel = await _visible_duel(duel_id, user_id)
    if duel.is_decidable_at(datetime.now(UTC)):
        settled = await offload(get_duel_operations().settle, duel)
        if settled is not None:
            duel = settled
    return _response(duel)


@router.post("/{duel_id}/accept", response_model=DuelResponse)
async def accept_duel(duel_id: str, user_id: str = Depends(get_current_user)):
    """Accepts a challenge and opens the window.

    Raises:
        HTTPException: 409 if the caller may not accept -- not theirs to
            answer, already answered, or lapsed.
    """
    duel = await _visible_duel(duel_id, user_id)
    if not duel.may_accept(user_id, datetime.now(UTC)):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This challenge can no longer be accepted",
        )
    accepted = await offload(get_duel_operations().accept, duel)
    if accepted is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This challenge can no longer be accepted",
        )
    return _response(accepted)


@router.post("/{duel_id}/decline", response_model=DuelResponse)
async def decline_duel(duel_id: str, user_id: str = Depends(get_current_user)):
    """Refuses a challenge.

    Raises:
        HTTPException: 409 if it is not the caller's to refuse, or no longer
            pending.
    """
    duel = await _visible_duel(duel_id, user_id)
    if not duel.may_decline(user_id, datetime.now(UTC)):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This challenge can no longer be declined",
        )
    declined = await offload(get_duel_operations().decline, duel)
    if declined is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This challenge can no longer be declined",
        )
    return _response(declined)


@router.delete("/{duel_id}", response_model=DuelResponse)
async def cancel_duel(duel_id: str, user_id: str = Depends(get_current_user)):
    """Withdraws a challenge the opponent has not answered.

    Raises:
        HTTPException: 409 once it has been accepted -- an active duel is
            played out, not taken back.
    """
    duel = await _visible_duel(duel_id, user_id)
    if not duel.may_cancel(user_id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only a pending challenge can be withdrawn",
        )
    cancelled = await offload(get_duel_operations().cancel, duel)
    if cancelled is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only a pending challenge can be withdrawn",
        )
    return _response(cancelled)
