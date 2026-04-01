"""Register endpoint for authentication routes."""
import logging

from fastapi import APIRouter, HTTPException, status

from app.api.v1.auth_helpers import build_auth_session
from app.core.security import hash_password
from app.core.storage import User, user_store
from app.core.supabase import supabase_client
from app.schemas import AuthSession, ErrorResponse, UserCreate

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/register",
    response_model=AuthSession,
    status_code=status.HTTP_201_CREATED,
    responses={
        409: {"model": ErrorResponse, "description": "Email already registered"},
        400: {"model": ErrorResponse, "description": "Invalid input data"},
    },
)
def register(user_data: UserCreate) -> AuthSession:
    """Register a new user account."""
    normalized_email = user_data.email.strip().lower() 

    if supabase_client.is_configured():
        if supabase_client.email_exists(normalized_email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists",
            )
    else:
        if user_store.exists_by_email(normalized_email): 
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists",
            )

    hashed_password = hash_password(user_data.password)
    user = User(
        email=normalized_email,
        hashed_password=hashed_password,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
    )

    if supabase_client.is_configured():
        try:
            created_user = supabase_client.insert_user_info(
                id=user.id,
                email=user.email,
                hashed_password=hashed_password,
                first_name=user.first_name,
                last_name=user.last_name,
                is_active=user.is_active,
            )
            if not created_user:
                logger.error(f"Failed to register user {user.email} in Supabase")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to register user. Please try again later.",
                )
            logger.info(f"User {user.email} registered successfully in Supabase")
        except HTTPException:
            raise
        except Exception as exception:
            logger.exception(f"Error registering user {user.email} in Supabase: {exception}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Registration failed. Please try again later.",
            )
    else:
        user_store.create(user)
        logger.warning("Supabase not configured; user stored locally only")

    return build_auth_session(user)
