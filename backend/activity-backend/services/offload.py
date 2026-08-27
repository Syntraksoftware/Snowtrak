"""Run a blocking Supabase call without stalling the event loop.

supabase-py is synchronous. Called directly from an `async def` handler it
holds the loop for the whole round trip -- ~440ms to ap-south-1 -- and every
other request in flight waits behind it. Adding the visibility filter puts a
second query in front of every activity list, which makes that worse, so it
is fixed here rather than left.

Identical to backend/community-backend/services/offload.py. Four lines
duplicated across two services beats a shared module that exists to hold
four lines.
"""

import asyncio
from functools import partial


async def offload(fn, *args, **kwargs):
    """Await a synchronous call on a worker thread instead of the event loop.

    Args:
        fn: A blocking callable, typically a Supabase client method.
        *args: Positional arguments forwarded to `fn`.
        **kwargs: Keyword arguments forwarded to `fn`.

    Returns:
        Whatever `fn` returns.
    """
    return await asyncio.to_thread(partial(fn, *args, **kwargs))
