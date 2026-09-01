"""Reading the follow graph.

The graph is owned by community-backend, which is the only service allowed
to write it. activity-backend reads it here rather than over HTTP: a hop to
community-backend would put two more round trips -- roughly 880ms -- in
front of every activity list, for one indexed read of a two-column table
whose shape is settled. Recorded as an exception in docs/service-ownership.md.
"""

import logging

logger = logging.getLogger(__name__)

# A read that walks the whole graph would be unbounded; nobody follows this
# many people, and past it the predicate belongs in a Postgres view.
# ponytail: cap the in-memory follow list, move to a DB-side join if it bites.
MAX_FOLLOW_IDS = 1000


def following_ids(client, user_id: str) -> list[str]:
    """Ids `user_id` follows, for a visibility filter.

    Only accepted edges: pending follows live in `follow_requests` and are
    not in this table at all.

    Args:
        client: A configured `supabase.Client`.
        user_id: The viewer.

    Returns:
        Up to `MAX_FOLLOW_IDS` ids, newest follow first. Empty on failure,
        which fails closed -- the caller sees only public rows.
    """
    if not user_id:
        return []
    try:
        response = (
            client.table("follows")
            .select("followee_id")
            .eq("follower_id", user_id)
            .order("created_at", desc=True)
            .limit(MAX_FOLLOW_IDS)
            .execute()
        )
        data = getattr(response, "data", None)
        if not isinstance(data, list):
            return []
        return [row["followee_id"] for row in data if row.get("followee_id")]
    except Exception as exception:
        logger.exception("Failed to list follows for %s: %s", user_id, exception)
        return []
