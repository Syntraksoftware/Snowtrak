"""Profile routes for authenticated and public user profile access."""
import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_current_user
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
        )


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
        profile_data = supabase_client.get_profile_by_id(current_user.id)
        if profile_data is None:
            profile_data = supabase_client.create_profile(
                user_id=current_user.id,
                full_name=_build_default_full_name(current_user),
            )
            if profile_data is None:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to create profile",
                )

        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error getting user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile",
        )


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
                )

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
        )
        if updated_profile is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile",
            )

        logger.info(f"User {current_user.id} profile updated")
        return ProfileResponse(**updated_profile)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error updating user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile",
        )


@router.get("/{user_id}/profile", response_model=ProfileResponse)
def get_user_profile_by_id(
    user_id: str,
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Get any user's profile by user identifier."""
    _ensure_database_configured()
    try:
        profile_data = supabase_client.get_profile_by_id(user_id)
        if profile_data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found",
            )

        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error getting user profile: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile",
        )
