"""Run blocking Supabase calls off the event loop."""

import asyncio
from collections.abc import Callable
from functools import partial
from typing import Any, TypeVar

T = TypeVar("T")


async def offload(fn: Callable[..., T], *args: Any, **kwargs: Any) -> T:
    """Await a synchronous Supabase call without stalling everything else.

    supabase-py is synchronous. A FastAPI handler declared `async def` runs on
    the event loop, so a blocking HTTP call inside one does not just make that
    request slow -- it stops every other request in flight until it returns.

    That is not theoretical. The database is ~440ms away, and one profile open
    fires several reads at once. Measured before this existed: five concurrent
    requests each took 8.1-8.6s, when any one of them alone took 0.5-1.4s.
    They were queueing behind each other on a single thread.

    Anything that reaches Supabase from an `async def` handler belongs in
    here. Handlers declared plain `def` do not need it -- FastAPI already runs
    those in a threadpool.
    """
    return await asyncio.to_thread(partial(fn, *args, **kwargs))
