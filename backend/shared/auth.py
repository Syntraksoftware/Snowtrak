"""Shared JWT authentication dependencies for backend services."""

from collections.abc import Callable

import jwt
from fastapi import Header, HTTPException, status


def build_auth_dependencies(
    *,
    jwt_secret: str,
    jwt_algorithm: str,
    logger=None,
) -> tuple[Callable, Callable]:
    """Create current/optional user dependencies using service config."""

    async def get_current_user(authorization: str | None = Header(None)) -> str:
        if not authorization:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token is missing",
            ) from None
        try:
            scheme, token = authorization.strip().split(" ", 1)
            if scheme.lower() != "bearer":
                raise ValueError("Invalid authorization scheme")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authorization header format",
            ) from None

        try:
            payload = jwt.decode(token, jwt_secret, algorithms=[jwt_algorithm])
            user_id = payload.get("sub")
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token payload",
                ) from None
            return user_id
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired",
            ) from None
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            ) from None
        except Exception as exc:  # pragma: no cover - defensive path
            if logger:
                logger.error(f"Authentication error: {exc}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication error",
            ) from None

    async def get_optional_user(
        authorization: str | None = Header(None),
    ) -> str | None:
        if not authorization:
            return None
        try:
            scheme, token = authorization.strip().split(" ", 1)
            if scheme.lower() != "bearer":
                return None
        except ValueError:
            return None

        try:
            payload = jwt.decode(token, jwt_secret, algorithms=[jwt_algorithm])
            return payload.get("sub")
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return None

    return get_current_user, get_optional_user
