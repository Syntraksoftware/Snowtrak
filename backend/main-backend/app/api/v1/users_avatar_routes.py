"""Avatar upload route for user profiles."""
import logging

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.api.dependencies import get_current_user
from app.core.storage import User
from app.core.supabase import supabase_client
from app.schemas import ProfileResponse

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/me/profile/avatar", response_model=ProfileResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Upload avatar image for current user profile."""
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured",
        )

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image",
        )

    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    if file_extension not in ["jpg", "jpeg", "png", "gif", "webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported image format. Use jpg, png, gif, or webp",
        )

    try:
        file_content = await file.read()
        maximum_file_size = 5 * 1024 * 1024
        if len(file_content) > maximum_file_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File size exceeds 5MB limit",
            )

        existing_profile = supabase_client.get_profile_by_id(current_user.id)
        old_avatar_url = None
        if existing_profile and existing_profile.get("avatar_url"):
            old_avatar_url = existing_profile["avatar_url"]

        new_avatar_url = supabase_client.upload_avatar(
            user_id=current_user.id,
            file_content=file_content,
            file_extension=file_extension,
        )
        if new_avatar_url is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to upload avatar",
            )

        if old_avatar_url and old_avatar_url != new_avatar_url:
            supabase_client.delete_avatar(current_user.id, old_avatar_url)

        updated_profile = supabase_client.update_profile(
            user_id=current_user.id,
            avatar_url=new_avatar_url,
        )
        if updated_profile is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile with new avatar",
            )

        logger.info(f"User {current_user.id} uploaded new avatar")
        return ProfileResponse(**updated_profile)

    except HTTPException:
        raise
    except Exception as exception:
        logger.exception(f"Error uploading avatar: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upload avatar",
        )
