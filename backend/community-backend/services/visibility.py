"""Who is allowed to see which post.

One predicate, built in one place, so that every read path enforces the same
rule. Filtering only the feed leaves four other doors open: a shared link, a
profile's post list, a subthread listing, and the preview of a quoted post.
"""

PUBLIC = "public"
FOLLOWERS = "followers"
PRIVATE = "private"

TIERS = (PUBLIC, FOLLOWERS, PRIVATE)

# The column is `not null default 'public'`, so a row can never be missing it.
DEFAULT_TIER = PUBLIC


def visible_posts_expression(
    viewer_id: str | None,
    following_ids: list[str] | None = None,
) -> str:
    """A PostgREST `or` for "posts this viewer may read".

        visibility = 'public'
        OR user_id = viewer
        OR (visibility = 'followers' AND user_id IN <people viewer follows>)

    A signed-out viewer collapses to the first clause alone. `private` is
    reachable only through the second: it has no clause of its own, because
    "only me" is exactly "I am the author".

    The follower clause is built only when the list is non-empty -- PostgREST
    rejects an empty `in.()`.
    """
    clauses = [f"visibility.eq.{PUBLIC}"]

    if viewer_id:
        clauses.append(f"user_id.eq.{viewer_id}")
        if following_ids:
            authors = ",".join(following_ids)
            clauses.append(f"and(visibility.eq.{FOLLOWERS},user_id.in.({authors}))")

    return ",".join(clauses)


def can_view(post: dict, viewer_id: str | None, following_ids: list[str] | None = None) -> bool:
    """The same rule, in Python, for rows already in hand.

    Used where a row arrives without having gone through the filter -- the
    preview embedded in a quoting post, for instance.
    """
    if not post:
        return False

    tier = str(post.get("visibility") or DEFAULT_TIER).lower()
    author = str(post.get("user_id") or "")

    if tier == PUBLIC:
        return True
    if viewer_id and author == viewer_id:
        return True
    if tier == FOLLOWERS and viewer_id:
        return author in (following_ids or [])
    return False
