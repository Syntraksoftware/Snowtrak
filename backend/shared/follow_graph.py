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


def follows_each_other(client, first_id: str, second_id: str) -> bool:
    """Whether two accounts follow each other.

    A duel is offered on a mutual follow, which is the closest thing this
    schema has to a friendship. Reading it here rather than inventing a
    second relationship keeps the privacy rule in one place: if the pair
    cannot see each other's profile, they cannot duel.

    One query for both directions -- the pair is small enough that two
    `in_` filters beat two round trips.

    Args:
        client: A configured `supabase.Client`.
        first_id: One account.
        second_id: The other.

    Returns:
        True only when both edges exist. False on failure, which fails
        closed: a challenge is refused rather than allowed on a bad read.
    """
    if not first_id or not second_id or first_id == second_id:
        return False
    pair = [first_id, second_id]
    try:
        response = (
            client.table("follows")
            .select("follower_id,followee_id")
            .in_("follower_id", pair)
            .in_("followee_id", pair)
            .limit(4)
            .execute()
        )
        data = getattr(response, "data", None)
        if not isinstance(data, list):
            return False
        edges = {(row.get("follower_id"), row.get("followee_id")) for row in data}
        return (first_id, second_id) in edges and (second_id, first_id) in edges
    except Exception as exception:
        logger.exception(
            "Failed to check mutual follow between %s and %s: %s",
            first_id,
            second_id,
            exception,
        )
        return False
