"""Profile routes for authenticated and public user profile access."""

import logging
from datetime import UTC, datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.api.dependencies import get_current_user
from app.core.profile_cache import get_profile, invalidate_profile, set_profile
from app.core.storage import User
from app.core.supabase import supabase_client
from app.schemas import ProfileResponse, ProfileUpdate

logger = logging.getLogger(__name__)
router = APIRouter()


def _ensure_database_configured() -> None:
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured",
        ) from None


def _profile_from_user_info(user_id: str) -> dict[str, Any] | None:
    """Build a profile for a user who has no row in `profiles`.

    Most users have none. `profiles.id` carries a foreign key to Supabase
    auth's `users` table, but registration writes to `user_info`, so every
    insert in `create_profile` fails with 23503 and the row is never made.

    `user_info` is always present -- it is what `posts.user_id` and
    `activities.user_id` reference -- so it is enough to render a profile
    from. Nothing is written: this is a read-time fallback, not a repair.
    """
    user = supabase_client.get_user_info_by_id(user_id)
    if user is None:
        return None

    first = (user.get("first_name") or "").strip()
    last = (user.get("last_name") or "").strip()
    email = (user.get("email") or "").strip()

    return {
        "id": user_id,
        "full_name": " ".join(p for p in (first, last) if p) or None,
        "username": email.split("@")[0] if "@" in email else None,
        "bio": None,
        "avatar_url": None,
        "push_token": None,
        "ski_level": None,
        "home": None,
        "country_code": None,
        # user_info.created_at is nullable even though it defaults to now().
        "created_at": user.get("created_at") or datetime.now(UTC),
        "updated_at": user.get("updated_at"),
    }


def _build_default_full_name(current_user: User) -> str | None:
    if current_user.first_name and current_user.last_name:
        return f"{current_user.first_name} {current_user.last_name}"
    if current_user.first_name:
        return current_user.first_name
    if current_user.last_name:
        return current_user.last_name
    return None


@router.get("/me/profile", response_model=ProfileResponse)
def get_current_user_profile_endpoint(
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Get current authenticated user's profile."""
    _ensure_database_configured()
    try:
        profile_data = get_profile(current_user.id)
        if profile_data is None:
            profile_data = supabase_client.get_profile_by_id(current_user.id)
            if profile_data is None:
                profile_data = supabase_client.create_profile(
                    user_id=current_user.id,
                    full_name=_build_default_full_name(current_user),
                )
            if profile_data is None:
                profile_data = _profile_from_user_info(current_user.id)
            if profile_data is None:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to create profile",
                ) from None
            set_profile(current_user.id, profile_data)

        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error getting user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile",
        ) from None


class PrivacySetting(BaseModel):
    """Whether this account approves its followers."""

    is_private: bool


@router.put("/me/privacy", response_model=PrivacySetting)
def set_my_privacy(
    setting: PrivacySetting,
    current_user: User = Depends(get_current_user),
) -> PrivacySetting:
    """Turn follower approval on or off.

    Existing followers are kept. Turning private does not retroactively hide
    followers-only content from people who already follow you -- the escape
    hatch for that is DELETE /api/v1/follows/me/followers/{id}.

    community-backend caches follow_stats, which carries this flag, for
    CACHE_FOLLOW_STATS_TTL_SECONDS. No invalidation is wired across the
    service boundary for one field.

    # ponytail: up to 120s of stale is_private in another viewer's cached
    # stats. POST /follows/{id} re-reads it fresh, so only the button's
    # label lags, never the gate. If that becomes visible, bump the
    # follow-stats cache version from here.
    """
    _ensure_database_configured()

    if not supabase_client.set_user_privacy(current_user.id, setting.is_private):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        ) from None

    invalidate_profile(current_user.id)
    return setting


@router.put("/me/profile", response_model=ProfileResponse)
def update_current_user_profile_endpoint(
    profile_update: ProfileUpdate,
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Update current user's profile details."""
    _ensure_database_configured()
    try:
        if profile_update.username is not None:
            is_username_taken = supabase_client.username_exists(
                profile_update.username,
                exclude_user_id=current_user.id,
            )
            if is_username_taken:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Username already taken",
                ) from None

        existing_profile = supabase_client.get_profile_by_id(current_user.id)
        if existing_profile is None:
            supabase_client.create_profile(user_id=current_user.id)

        updated_profile = supabase_client.update_profile(
            user_id=current_user.id,
            full_name=profile_update.full_name,
            username=profile_update.username,
            bio=profile_update.bio,
            avatar_url=profile_update.avatar_url,
            push_token=profile_update.push_token,
            ski_level=profile_update.ski_level,
            home=profile_update.home,
            country_code=profile_update.country_code,
        )
        if updated_profile is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile",
            ) from None

        invalidate_profile(current_user.id)
        logger.info(f"User {current_user.id} profile updated")
        return ProfileResponse(**updated_profile)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error updating user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile",
        ) from None


@router.get("/{user_id}/profile", response_model=ProfileResponse)
def get_user_profile_by_id(
    user_id: str,
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Get any user's profile by user identifier."""
    _ensure_database_configured()
    try:
        profile_data = get_profile(user_id)
        if profile_data is None:
            profile_data = supabase_client.get_profile_by_id(user_id)
            if profile_data is None:
                profile_data = _profile_from_user_info(user_id)
            if profile_data is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Profile not found",
                ) from None
            set_profile(user_id, profile_data)

        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error getting user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile",
        ) from None
