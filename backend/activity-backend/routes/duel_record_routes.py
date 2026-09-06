"""A player's win/loss record.

Its own router because it hangs off /users, not /duels: the profile header
asks for it by user id, and nesting it under a duel id would be a lie about
what it belongs to.
"""

import logging

from fastapi import APIRouter, Depends

from middleware.auth import get_current_user
from routes.competition_models import DuelRecord
from services.duel_operations import get_duel_operations
from services.offload import offload

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/users", tags=["duels"])


@router.get("/{user_id}/duel_record", response_model=DuelRecord)
async def duel_record(user_id: str, _: str = Depends(get_current_user)):
    """Wins, losses, draws and recent form.

    Public to any signed-in caller: a record is a scoreboard, and it names
    no activity and no opponent.
    """
    record = await offload(get_duel_operations().record, user_id)
    return DuelRecord(user_id=user_id, **record)
