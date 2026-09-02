"""Background settlement for duels and the weekly board.

Rides the same lifespan pattern as `PipelineWorker`, which is the reason
this feature needs no scheduler, no cron and no scheduled workflow.

Every write it makes is idempotent, so running it on more than one replica
is not a correctness problem: duel updates are conditional on the duel still
being active, and snapshot rows are upserted on their primary key. The cost
of a duplicate run is a wasted query, not a wrong result.

Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md
"""

from __future__ import annotations

import asyncio
import logging
from datetime import UTC, date, datetime

from domain.competition.metrics import week_start
from services.duel_operations import get_duel_operations
from services.leaderboard_operations import get_leaderboard_operations

logger = logging.getLogger(__name__)

#: A duel that ended is stale for at most this long, and a settled week
#: appears at most this late. Both are read paths a user can also trigger
#: directly, so the sweep is a backstop rather than the mechanism.
SWEEP_SECONDS = 300


class SettlementWorker:
    """Closes finished duels, expires stale invitations, snapshots weeks."""

    def __init__(self, interval_seconds: int = SWEEP_SECONDS) -> None:
        self._interval = interval_seconds
        self._running = False
        # Which week has already been snapshotted by *this* process. A
        # restart re-runs one snapshot, which the upsert absorbs.
        self._last_settled_week: date | None = None

    async def run_forever(self) -> None:
        """Sweeps until `stop`.

        One failed sweep must not end the loop -- the next one would settle
        the same duels anyway, and a worker that dies on a transient
        Supabase error silently stops settling for everyone.
        """
        self._running = True
        logger.info("Settlement worker started interval=%ss", self._interval)
        while self._running:
            try:
                await self.sweep(datetime.now(UTC))
            except Exception:
                logger.exception("Settlement sweep failed; continuing")
            await asyncio.sleep(self._interval)

    async def sweep(self, now: datetime) -> None:
        """One pass: duels, then invitations, then the week just ended."""
        duels = get_duel_operations()

        settled = await asyncio.to_thread(duels.settle_due, now)
        if settled:
            logger.info("Settled %d duel(s)", settled)

        expired = await asyncio.to_thread(duels.expire_stale, now)
        if expired:
            logger.info("Expired %d stale challenge(s)", expired)

        await self._settle_finished_week(now)

    async def _settle_finished_week(self, now: datetime) -> None:
        """Snapshots the week that has just ended, once.

        Deliberately settles the *previous* week: the current one is still
        being skied, and a snapshot of it would be overwritten every sweep
        for seven days.
        """
        current = week_start(now)
        if self._last_settled_week == current:
            return
        previous = datetime.fromordinal(current.toordinal() - 1).replace(tzinfo=UTC)
        await asyncio.to_thread(get_leaderboard_operations().settle_week, previous)
        self._last_settled_week = current

    def stop(self) -> None:
        self._running = False
