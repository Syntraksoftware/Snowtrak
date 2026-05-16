"""Shared helpers for authentication route modules."""

from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status

from app.core.config import settings
from app.core.jwt import create_access_token, create_refresh_token
from app.core.storage import User
from app.schemas import AuthSession, UserResponse


def build_auth_session(user: User) -> AuthSession:
    """Create authentication session tokens and user payload."""
    token_data = {
        "sub": user.id,
        "email": user.email,
    }

    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    expires_at = datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes)

    return AuthSession(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_at=expires_at,
        user=UserResponse(
            id=user.id,
            email=user.email,
            first_name=user.first_name,
            last_name=user.last_name,
        ),
    )


def build_user_from_supabase_record(supabase_user_record: dict, error_context: str) -> User:
    """Convert a Supabase record to local User object with validation."""
    user_identifier = supabase_user_record.get("id")
    email_address = supabase_user_record.get("email")
    hashed_password = supabase_user_record.get("hashed_password")

    if not user_identifier or not email_address or not hashed_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid user record for {error_context}",
        ) from None

    is_active = supabase_user_record.get("is_active", True)
    return User(
        id=user_identifier,
        email=email_address,
        hashed_password=hashed_password,
        first_name=supabase_user_record.get("first_name"),
        last_name=supabase_user_record.get("last_name"),
        is_active=is_active,
    )
