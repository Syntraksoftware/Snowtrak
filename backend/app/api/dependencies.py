"""
Authentication dependencies for protected routes.
Provides current user injection via JWT validation.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from fastapi.security.http import HTTPAuthorizationCredentials
from jose import JWTError
from app.core.jwt import decode_token, verify_token_type
from app.core.storage import User, user_store

# HTTP Bearer token scheme
security = HTTPBearer()


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """
    Dependency to get current authenticated user from JWT token.
    
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
    
    try:
        # Decode JWT token
        token_data = decode_token(credentials.credentials)
        
        # Verify it's an access token
        if not verify_token_type(token_data, "access"):
            raise credentials_exception
        
        # Get user from storage
        user = user_store.get_by_id(token_data.user_id)
        
        if user is None:
            raise credentials_exception
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is disabled"
            )
        
        return user
        
    except JWTError:
        raise credentials_exception
