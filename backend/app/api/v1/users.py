"""
User API endpoints.
Handles user profile management.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas import UserResponse, UserUpdate
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
