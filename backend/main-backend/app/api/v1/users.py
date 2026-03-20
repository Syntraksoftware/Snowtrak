"""
User API endpoints.
Handles user profile management.
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from app.schemas import UserResponse, UserUpdate, ProfileResponse, ProfileUpdate
from app.core.storage import User
from app.core.supabase import supabase_client
from app.api.dependencies import get_current_user
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)) -> UserResponse:
    """
    Get current authenticated user's profile.
    
    Requires valid access token in Authorization header.
    """
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        first_name=current_user.first_name,
        last_name=current_user.last_name,
    )


@router.put("/me", response_model=UserResponse)
def update_current_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """
    Update current user's profile.
    
    - **first_name**: Update first name
    - **last_name**: Update last name
    
    Updates are synchronized to Supabase if configured, otherwise stored locally.
    """
    # Update Supabase if configured
    if supabase_client.is_configured():
        try:
            updated_user = supabase_client.update_user_info(
                id=current_user.id,
                first_name=user_update.first_name,
                last_name=user_update.last_name,
            )
            
            if not updated_user:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to update user profile"
                )
            
            # Update local user object with new values
            if user_update.first_name is not None:
                current_user.first_name = user_update.first_name
            if user_update.last_name is not None:
                current_user.last_name = user_update.last_name
            
            logger.info(f"User {current_user.id} profile updated in Supabase")
            
        except HTTPException:
            raise
        except Exception as e:
            logger.exception(f"Error updating user profile in Supabase: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update user profile"
            )
    else:
        # Fallback to local storage
        if user_update.first_name is not None:
            current_user.first_name = user_update.first_name
        if user_update.last_name is not None:
            current_user.last_name = user_update.last_name
        
        logger.warning("Supabase not configured; user profile updated locally only")
    
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        first_name=current_user.first_name,
        last_name=current_user.last_name,
    )


@router.get("/me/profile", response_model=ProfileResponse)
def get_current_user_profile_endpoint(current_user: User = Depends(get_current_user)) -> ProfileResponse:
    """
    Get current authenticated user's profile.
    
    Returns profile data including full_name, username, bio, avatar_url, etc.
    Creates a default profile if one doesn't exist.
    """
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured"
        )
    
    try:
        # Try to get existing profile
        profile_data = supabase_client.get_profile_by_id(current_user.id)
        
        if profile_data is None:
            # Create default profile if it doesn't exist
            full_name = None
            if current_user.first_name and current_user.last_name:
                full_name = f"{current_user.first_name} {current_user.last_name}"
            elif current_user.first_name:
                full_name = current_user.first_name
            elif current_user.last_name:
                full_name = current_user.last_name
            
            profile_data = supabase_client.create_profile(
                user_id=current_user.id,
                full_name=full_name,
            )
            
            if profile_data is None:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to create profile"
                )
        
        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile"
        )


@router.put("/me/profile", response_model=ProfileResponse)
def update_current_user_profile_endpoint(
    profile_update: ProfileUpdate,
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """
    Update current user's profile.
    
    - **full_name**: Update full name
    - **username**: Update username (must be unique)
    - **bio**: Update biography
    - **avatar_url**: Update avatar image URL
    - **push_token**: Update push notification token
    - **ski_level**: Update ski level
    - **home**: Update home/nationality
    
    Username must be unique across all users.
    """
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured"
        )
    
    try:
        # Check username uniqueness if username is being updated
        if profile_update.username is not None:
            if supabase_client.username_exists(profile_update.username, exclude_user_id=current_user.id):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Username already taken"
                )
        
        # Ensure profile exists before updating
        existing_profile = supabase_client.get_profile_by_id(current_user.id)
        if existing_profile is None:
            # Create profile first if it doesn't exist
            supabase_client.create_profile(user_id=current_user.id)
        
        # Update profile
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
                detail="Failed to update profile"
            )
        
        logger.info(f"User {current_user.id} profile updated")
        return ProfileResponse(**updated_profile)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error updating user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile"
        )


@router.get("/{user_id}/profile", response_model=ProfileResponse)
def get_user_profile_by_id(
    user_id: str,
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """
    Get any user's profile by user ID.
    
    Returns profile data for the specified user.
    """
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured"
        )
    
    try:
        profile_data = supabase_client.get_profile_by_id(user_id)
        
        if profile_data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found"
            )
        
        return ProfileResponse(**profile_data)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile"
        )


@router.post("/me/profile/avatar", response_model=ProfileResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """
    Upload avatar image for current user.
    
    Accepts image files (jpg, png, etc.) and uploads to Supabase storage bucket 'avatars'.
    Updates the user's profile with the new avatar URL.
    
    arguments: 
    - file: UploadFile, the image file to upload
    - current_user: User, the current user
    
    Expected Return:
    - ProfileResponse: the profile response containing the new avatar URL
    - e.g. {
        "id": "123",
        "full_name": "John Doe",
        "username": "johndoe",
        "bio": "I am a software engineer",
        "avatar_url": "https://example.com/avatar.jpg",
        "push_token": "1234567890",
        "ski_level": "beginner",
        "home": "New York",
        "created_at": "2021-01-01 12:00:00",
        "updated_at": "2021-01-01 12:00:00"
    }
    """
    if not supabase_client.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not configured"
        )
    
    # Validate file type
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Get file extension
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    if file_extension not in ["jpg", "jpeg", "png", "gif", "webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported image format. Use jpg, png, gif, or webp"
        )
    
    try:
        # Read file content
        file_content = await file.read()
        
        # Check file size (max 5MB)
        max_size = 5 * 1024 * 1024  # 5MB
        if len(file_content) > max_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File size exceeds 5MB limit"
            )
        
        # Get existing profile to delete old avatar if exists
        existing_profile = supabase_client.get_profile_by_id(current_user.id)
        old_avatar_url = None
        if existing_profile and existing_profile.get("avatar_url"):
            old_avatar_url = existing_profile["avatar_url"]
        
        # Upload new avatar
        new_avatar_url = supabase_client.upload_avatar(
            user_id=current_user.id,
            file_content=file_content,
            file_extension=file_extension,
        )
        
        if new_avatar_url is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to upload avatar"
            )
        
        # Delete old avatar if it exists
        if old_avatar_url and old_avatar_url != new_avatar_url:
            supabase_client.delete_avatar(current_user.id, old_avatar_url)
        
        # Update profile with new avatar URL
        updated_profile = supabase_client.update_profile(
            user_id=current_user.id,
            avatar_url=new_avatar_url,
        )
        
        if updated_profile is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile with new avatar"
            )
        
        logger.info(f"User {current_user.id} uploaded new avatar")
        return ProfileResponse(**updated_profile)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error uploading avatar: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upload avatar"
        )
