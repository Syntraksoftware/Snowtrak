"""
Authentication dependencies for protected routes.
Provides current user injection via JWT validation.
"""

import logging
from datetime import datetime

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from fastapi.security.http import HTTPAuthorizationCredentials
from jose import JWTError

from app.core.jwt import decode_token, verify_token_type
from app.core.storage import User, user_store
from app.core.supabase import supabase_client

logger = logging.getLogger(__name__)

# HTTP Bearer token scheme
# Set auto_error=False to handle missing token ourselves and return 401
security = HTTPBearer(auto_error=False)


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """
    Dependency to get current authenticated user from JWT token.

    First tries to fetch from Supabase, falls back to in-memory storage if not configured.

    Usage:
        @router.get("/protected")
        def protected_route(current_user: User = Depends(get_current_user)):
            return {"user_id": current_user.id}

    Args:
        credentials: Bearer token from Authorization header

    Returns:
        Authenticated User

    Raises:
        HTTPException: If token is invalid or user not found
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # Handle missing token
    if credentials is None:
        raise credentials_exception

    try:
        # Decode JWT token
        token_data = decode_token(credentials.credentials)

        # Verify it's an access token
        if not verify_token_type(token_data, "access"):
            raise credentials_exception

        user_id = token_data.user_id
        if not user_id:
            raise credentials_exception

        # get user from Supabase first
        if supabase_client.is_configured():
            supabase_user = supabase_client.get_user_info_by_id(user_id)

            if not supabase_user:
                raise credentials_exception

            # Use consistent default (True) for is_active - missing field treated as active
            is_active = supabase_user.get("is_active", True)

            if not is_active:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN, detail="User account is disabled"
                )

            # Validate required Supabase fields
            user_id = supabase_user.get("id")
            email = supabase_user.get("email")
            hashed_password = supabase_user.get("hashed_password")

            if not user_id or not email or not hashed_password:
                logger.error(
                    "Supabase user record missing required fields for user_id=%s",
                    token_data.user_id,
                )
                raise credentials_exception

            # Convert Supabase dict to User object
            user = User(
                id=user_id,
                email=email,
                hashed_password=hashed_password,
                first_name=supabase_user.get("first_name"),
                last_name=supabase_user.get("last_name"),
                is_active=is_active,
            )

            # Parse last_login_at if present
            last_login = supabase_user.get("last_login_at")
            if last_login:
                try:
                    if isinstance(last_login, str):
                        user.last_login_at = datetime.fromisoformat(
                            last_login.replace("Z", "+00:00")
                        )
                    elif isinstance(last_login, datetime):
                        user.last_login_at = last_login
                except Exception as e:
                    logger.warning(f"Failed to parse last_login_at: {e}")

            return user

        # Fallback to in-memory storage if Supabase not configured
        user = user_store.get_by_id(user_id)

        if user is None:
            raise credentials_exception

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="User account is disabled"
            )

        return user

    except JWTError:
        raise credentials_exception from None
