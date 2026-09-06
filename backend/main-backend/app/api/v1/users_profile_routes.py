"""Profile routes for authenticated and public user profile access."""

import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.core.profile_cache import get_profile, invalidate_profile, set_profile
from app.core.profile_identity import profile_with_identity
from app.core.storage import User
from app.core.supabase import supabase_client
from app.schemas import ProfileResponse, ProfileUpdate, UsernameSetting

logger = logging.getLogger(__name__)
router = APIRouter()


def _ensure_database_configured() -> None:
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured",
        ) from None


@router.get("/me/profile", response_model=ProfileResponse)
def get_current_user_profile_endpoint(
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Get current authenticated user's profile."""
    _ensure_database_configured()
    try:
        profile_data = get_profile(current_user.id)
        if profile_data is None:
            row = supabase_client.get_profile_by_id(current_user.id)
            if row is None:
                row = supabase_client.create_profile(user_id=current_user.id)
            # Overlaid before caching: a row cached without its identity
            # fields would serve a nameless profile for the whole TTL.
            profile_data = profile_with_identity(current_user.id, row)
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
    """Update current user's profile details.

    `full_name` and `username` are not settable here -- both moved to
    `user_info` in migration 022. Use PUT /me/username for the handle; the
    full name is derived from `user_info.first_name`/`last_name`.
    """
    _ensure_database_configured()
    try:
        existing_profile = supabase_client.get_profile_by_id(current_user.id)
        if existing_profile is None:
            supabase_client.create_profile(user_id=current_user.id)

        updated_profile = supabase_client.update_profile(
            user_id=current_user.id,
            bio=profile_update.bio,
            avatar_url=profile_update.avatar_url,
            push_token=profile_update.push_token,
            ski_level=profile_update.ski_level,
            home=profile_update.home,
        )
        if updated_profile is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile",
            ) from None

        # The write returns a bare `profiles` row, which no longer holds a
        # name -- overlay it or the save reads back blank.
        profile_data = profile_with_identity(current_user.id, updated_profile) or updated_profile

        invalidate_profile(current_user.id)
        logger.info(f"User {current_user.id} profile updated")
        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error updating user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile",
        ) from None


class CountrySetting(BaseModel):
    """Which country leaderboard this account appears on."""

    country_code: str | None = Field(
        None,
        min_length=2,
        max_length=2,
        description="ISO 3166-1 alpha-2, or null for the global board only",
    )


@router.put("/me/country", response_model=CountrySetting)
def set_my_country(
    setting: CountrySetting,
    current_user: User = Depends(get_current_user),
) -> CountrySetting:
    """Choose the country leaderboard to appear on.

    Its own route rather than a field on PUT /me/profile, for the same
    reason /me/privacy is: that route writes `profiles`, which has no row
    for anyone, so the value would be accepted and lost.

    Null clears it -- the user then appears on the global board only. It is
    read at query time, so a change takes effect on the next board read; no
    backfill and nothing to invalidate beyond the profile cache.
    """
    _ensure_database_configured()

    if not supabase_client.set_user_country(current_user.id, setting.country_code):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        ) from None

    invalidate_profile(current_user.id)
    return setting


@router.put("/me/username", response_model=UsernameSetting)
def set_my_username(
    setting: UsernameSetting,
    current_user: User = Depends(get_current_user),
) -> UsernameSetting:
    """Choose the handle this account is known by.

    Its own route rather than a field on PUT /me/profile, for the same
    reason /me/privacy and /me/country are: those write `user_info`, and
    that is where a name has to live for a feed to read it.

    Stored lower-cased so `@snowking` has one spelling. Null clears it and
    the display falls back to the user's name.

    Raises:
        HTTPException: 409 if another account already has the handle, 404 if
            the user is gone.
    """
    _ensure_database_configured()

    handle = setting.username.lower() if setting.username else None

    if handle and supabase_client.username_exists(handle, exclude_user_id=current_user.id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="That username is taken",
        ) from None

    if not supabase_client.set_username(current_user.id, handle):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        ) from None

    invalidate_profile(current_user.id)
    return UsernameSetting(username=handle)


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
            # Overlaid before caching, for the same reason as /me/profile.
            profile_data = profile_with_identity(
                user_id, supabase_client.get_profile_by_id(user_id)
            )
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
