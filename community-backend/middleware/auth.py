"""Authentication utilities for JWT verification."""
from typing import Optional
from fastapi import Depends, HTTPException, status, Header
import jwt
import logging
from config import get_config

config = get_config()
logger = logging.getLogger(__name__)


async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """
    Dependency to extract and verify JWT token from Authorization header.
    Required for protected endpoints.
    
    Returns:
        user_id: The user ID from the token's 'sub' claim
        
    Raises:
        HTTPException: 401 if token is missing or invalid
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is missing"
        )
    
    # Parse "Bearer <token>" format
    try:
        scheme, token = authorization.strip().split(" ", 1)
        if scheme.lower() != "bearer":
            raise ValueError("Invalid authorization scheme")
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format"
        )
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid JWT token"
        )
    
    try:
        # Decode JWT token
        payload = jwt.decode(
            token,
            config.JWT_SECRET,
            algorithms=[config.JWT_ALGORITHM]
        )
        
        # Extract user_id from token
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
        
        return user_id
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    except Exception as e:
        logger.error(f"Authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Authentication error: {str(e)}"
        )


async def get_optional_user(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """
    Dependency to extract JWT token from Authorization header if present (optional).
    Returns None if no token provided.
    
    Returns:
        user_id: The user ID from the token's 'sub' claim, or None
    """
    if not authorization:
        return None
    
    # Parse "Bearer <token>" format
    try:
        scheme, token = authorization.strip().split(" ", 1)
        if scheme.lower() != "bearer":
            return None
    except ValueError:
        return None
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None
    
    try:
        # Decode JWT token
        payload = jwt.decode(
            token,
            config.JWT_SECRET,
            algorithms=[config.JWT_ALGORITHM]
        )
        
        # Extract user_id from token
        user_id = payload.get("sub")
        return user_id
        
    except:
        # Silently ignore invalid tokens for optional auth
        return None
