"""
JWT token creation and validation utilities.
"""

from datetime import UTC, datetime, timedelta
from typing import Any

from jose import JWTError, jwt

from app.core.config import settings
from app.schemas import TokenData


def create_access_token(data: dict[str, Any], expires_delta: timedelta | None = None) -> str:
    """
    Create a JWT access token.

    Args:
        data: Payload data to encode (should include user_id, email)
        expires_delta: Custom expiration time, defaults to settings value

    Returns:
        Encoded JWT token string
    """
    to_encode = data.copy()
    now = datetime.now(UTC)

    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.access_token_expire_minutes)

    to_encode.update({"exp": expire, "iat": now, "type": "access"})

    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def create_refresh_token(data: dict[str, Any]) -> str:
    """
    Create a JWT refresh token with longer expiration.

    Args:
        data: Payload data to encode

    Returns:
        Encoded JWT refresh token string
    """
    import secrets

    to_encode = data.copy()
    now = datetime.now(UTC)
    expire = now + timedelta(days=settings.refresh_token_expire_days)

    # Add a random nonce to ensure each refresh token is unique
    # This prevents token reuse even if generated at the same timestamp
    to_encode.update(
        {
            "exp": expire,
            "iat": now,
            "type": "refresh",
            "nonce": secrets.token_urlsafe(16),  # Add random nonce for uniqueness
        }
    )

    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def decode_token(token: str) -> TokenData:
    """
    Decode and validate a JWT token.

    Args:
        token: JWT token string

    Returns:
        TokenData with extracted payload

    Raises:
        JWTError: If token is invalid or expired
    """
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id: str = payload.get("sub")
        email: str = payload.get("email")
        token_type: str = payload.get("type")

        if user_id is None:
            raise JWTError("Token missing user ID")

        return TokenData(user_id=user_id, email=email, token_type=token_type)
    except JWTError as e:
        raise JWTError(f"Invalid token: {str(e)}") from e


def verify_token_type(token_data: TokenData, expected_type: str) -> bool:
    """
    Verify token is of expected type (access/refresh).

    Args:
        token_data: Decoded token data
        expected_type: Expected token type ("access" or "refresh")

    Returns:
        True if token type matches
    """
    return token_data.token_type == expected_type
