"""Login endpoint for authentication routes."""

import logging
from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, status

from app.api.v1.auth_helpers import build_auth_session, build_user_from_supabase_record
from app.core.security import verify_password
from app.core.storage import user_store
from app.core.supabase import supabase_client
from app.schemas import AuthSession, ErrorResponse, LoginRequest

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/login",
    response_model=AuthSession,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid credentials"},
        403: {"model": ErrorResponse, "description": "Account disabled"},
    },
)
def login(credentials: LoginRequest) -> AuthSession:
    """Authenticate user and obtain tokens."""
    normalized_email = credentials.email.strip().lower()

    if supabase_client.is_configured():
        supabase_user_record = supabase_client.get_user_info_by_email(normalized_email)
        if not supabase_user_record:
            logger.info("Login failed: user not found for email=%s", normalized_email)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            ) from None

        hashed_password = supabase_user_record.get("hashed_password", "")
        if not verify_password(credentials.password, hashed_password):
            logger.info("Login failed: invalid password for email=%s", normalized_email)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            ) from None

        if not supabase_user_record.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is disabled",
            ) from None

        try:
            supabase_client.update_user_last_login(supabase_user_record.get("id"))
        except Exception as exception:
            logger.warning(f"Failed to update last_login_at: {exception}")

        user = build_user_from_supabase_record(
            supabase_user_record=supabase_user_record,
            error_context=normalized_email,
        )
        user.last_login_at = datetime.now(UTC)
        logger.info(f"User {credentials.email} logged in via Supabase")
        return build_auth_session(user)

    user = user_store.get_by_email(normalized_email)
    if not user or not verify_password(credentials.password, user.hashed_password):
        logger.info("Login failed in fallback store for email=%s", normalized_email)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        ) from None

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled",
        ) from None

    user.last_login_at = datetime.now(UTC)
    return build_auth_session(user)
