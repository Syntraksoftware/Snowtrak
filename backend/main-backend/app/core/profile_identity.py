"""Overlay `user_info` identity fields onto a `profiles` row.

Shared by every route that returns a `ProfileResponse` --
`users_profile_routes.py` and `users_avatar_routes.py` -- so it lives here,
in `core`, rather than in either route module. A route module importing a
helper out of a sibling route module is a layering smell even where it
happens not to cycle; `core` is where both already look for shared logic
(see `profile_cache.py` next door).
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from app.core.supabase import supabase_client


def profile_with_identity(
    user_id: str,
    profile: dict[str, Any] | None,
) -> dict[str, Any] | None:
    """Merge a `profiles` row with the identity fields `user_info` owns.

    The overlay is unconditional, not a not-found fallback. Migration 022
    dropped `profiles.full_name` and moved `username` to `user_info`;
    `country_code` moved there in 021. A `profiles` row therefore carries
    none of the three, so a response built from that row alone would show no
    name at all -- which is exactly what applying 022 would do to the 41
    users it gives a row to.

    `profile` may be None. `user_info` is always present for a live user --
    it is what `posts.user_id` and `activities.user_id` reference -- so it is
    enough to render a profile from on its own. Nothing is written here.

    Args:
        user_id: The user being rendered.
        profile: Their `profiles` row, or None if they have none yet.

    Returns:
        A full profile payload, or None when neither table has the user.
    """
    user = supabase_client.get_user_info_by_id(user_id)
    if user is None and profile is None:
        return None

    user = user or {}
    row = profile or {}
    first = (user.get("first_name") or "").strip()
    last = (user.get("last_name") or "").strip()

    return {
        "id": user_id,
        # Presentation: profiles owns these.
        "bio": row.get("bio"),
        "avatar_url": row.get("avatar_url"),
        "push_token": row.get("push_token"),
        "ski_level": row.get("ski_level"),
        "home": row.get("home"),
        # Identity: user_info owns these, since migrations 021 and 022.
        "full_name": " ".join(p for p in (first, last) if p) or None,
        "username": user.get("username"),
        "country_code": user.get("country_code"),
        # user_info.created_at is nullable even though it defaults to now().
        "created_at": row.get("created_at") or user.get("created_at") or datetime.now(UTC),
        "updated_at": row.get("updated_at") or user.get("updated_at"),
    }
