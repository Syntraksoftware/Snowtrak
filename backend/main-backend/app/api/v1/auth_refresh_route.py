"""Token refresh endpoint for authentication routes."""
import logging

from fastapi import APIRouter, HTTPException, status
from jose import JWTError

from app.api.v1.auth_helpers import build_auth_session, build_user_from_supabase_record
from app.core.jwt import decode_token, verify_token_type
from app.core.storage import user_store
from app.core.supabase import supabase_client
from app.schemas import AuthSession, ErrorResponse, RefreshTokenRequest

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/refresh",
    response_model=AuthSession,
    responses={
        401: {
            "model": ErrorResponse,
            "description": "Invalid or expired refresh token",
        },
    },
)
def refresh_token(request: RefreshTokenRequest) -> AuthSession:
    """Obtain new access token using refresh token."""
    try:
        token_data = decode_token(request.refresh_token)
        if not verify_token_type(token_data, "refresh"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )

        user_identifier = token_data.user_id
        if not user_identifier:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )

        if supabase_client.is_configured():
            supabase_user_record = supabase_client.get_user_info_by_id(user_identifier)
            if not supabase_user_record:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found or inactive",
                )

            if not supabase_user_record.get("is_active", True):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found or inactive",
                )

            user = build_user_from_supabase_record(
                supabase_user_record=supabase_user_record,
                error_context=user_identifier,
            )
            return build_auth_session(user)

        user = user_store.get_by_id(user_identifier)
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive",
            )

        return build_auth_session(user)

    except JWTError as exception:
        logger.info(f"Refresh token error: {exception}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid refresh token: {str(exception)}",
        )
