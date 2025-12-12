"""
Authentication API endpoints.
Handles registration, login, and token refresh.
"""
from fastapi import APIRouter, HTTPException, status
from datetime import datetime, timedelta
from app.schemas import UserCreate, LoginRequest, RefreshTokenRequest, AuthSession, ErrorResponse, UserResponse
from app.core.storage import User, user_store
from app.core.security import hash_password, verify_password
from app.core.jwt import create_access_token, create_refresh_token, decode_token, verify_token_type
from app.core.config import settings
from app.core.supabase import supabase_client
from jose import JWTError
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=AuthSession,
    status_code=status.HTTP_201_CREATED,
    responses={
        409: {"model": ErrorResponse, "description": "Email already registered"},
        400: {"model": ErrorResponse, "description": "Invalid input data"},
    }
)
def register(user_data: UserCreate) -> AuthSession:
    """
    Register a new user account.
    
    - **email**: Valid email address (must be unique)
    - **password**: Minimum 8 characters
    - **first_name**: Optional first name
    - **last_name**: Optional last name
    
    Returns authentication session with access/refresh tokens.
    """
    # Check if email exists in Supabase
    if supabase_client.is_configured():
        if supabase_client.email_exists(user_data.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists"
            )
    else:
        # Fallback to user_store if Supabase not configured
        if user_store.exists_by_email(user_data.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists"
            )
    
    # Create user locally for session data
    hashed_pwd = hash_password(user_data.password)
    user = User(
        email=user_data.email,
        hashed_password=hashed_pwd,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
    )
    
    # Insert into Supabase
    if supabase_client.is_configured():
        try:
            result = supabase_client.insert_user_info(
                id=user.id,
                email=user.email,
                hashed_password=hashed_pwd,
                first_name=user.first_name,
                last_name=user.last_name,
                is_active=user.is_active,
            )
            if result:
                logger.info(f"User {user.email} registered in Supabase")
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to register user"
                )
        except Exception as e:
            logger.exception(f"Error registering user {user.email}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Registration failed"
            )
    else:
        # Fallback to local storage
        user_store.create(user)
        logger.warning("Supabase not configured; user stored locally only")
    
    # Generate tokens
    return _create_session(user)


@router.post(
    "/login",
    response_model=AuthSession,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid credentials"},
        403: {"model": ErrorResponse, "description": "Account disabled"},
    }
)
def login(credentials: LoginRequest) -> AuthSession:
    """
    Authenticate user and obtain tokens.
    
    Accepts JSON data:
    - **email**: Registered email address
    - **password**: User password
    
    Returns authentication session with access/refresh tokens.
    """
    # Fetch user from Supabase
    if supabase_client.is_configured():
        supabase_user = supabase_client.get_user_info_by_email(credentials.email)
        
        if not supabase_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Verify password
        if not verify_password(credentials.password, supabase_user.get("hashed_password", "")):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Check if account is active
        if not supabase_user.get("is_active", False):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is disabled"
            )
        
        # Update last login in Supabase
        try:
            supabase_client.update_user_last_login(supabase_user["id"])
        except Exception as e:
            logger.warning(f"Failed to update last_login_at: {e}")
        
        # Create local User object for session
        user = User(
            id=supabase_user["id"],
            email=supabase_user["email"],
            hashed_password=supabase_user["hashed_password"],
            first_name=supabase_user.get("first_name"),
            last_name=supabase_user.get("last_name"),
            is_active=supabase_user.get("is_active", True),
        )
        user.last_login_at = datetime.utcnow()
        
        logger.info(f"User {credentials.email} logged in via Supabase")
        return _create_session(user)
    
    else:
        # Fallback to user_store if Supabase not configured
        user = user_store.get_by_email(credentials.email)
        
        if not user or not verify_password(credentials.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is disabled"
            )
        
        user.last_login_at = datetime.utcnow()
        return _create_session(user)


@router.post(
    "/refresh",
    response_model=AuthSession,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid or expired refresh token"},
    }
)
def refresh_token(request: RefreshTokenRequest) -> AuthSession:
    """
    Obtain new access token using refresh token.
    
    - **refresh_token**: Valid refresh token from login/register
    
    Returns new authentication session with updated tokens.
    """
    try:
        # Decode refresh token
        token_data = decode_token(request.refresh_token)
        
        # Verify it's a refresh token
        if not verify_token_type(token_data, "refresh"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        user_id = token_data.user_id
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Get user from Supabase
        if supabase_client.is_configured():
            supabase_user = supabase_client.get_user_info_by_id(user_id)
            
            if not supabase_user or not supabase_user.get("is_active"):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found or inactive"
                )
            
            # Create local User object for session
            user = User(
                id=supabase_user["id"],
                email=supabase_user["email"],
                hashed_password=supabase_user["hashed_password"],
                first_name=supabase_user.get("first_name"),
                last_name=supabase_user.get("last_name"),
                is_active=supabase_user.get("is_active", True),
            )
        else:
            # Fallback to user_store
            user = user_store.get_by_id(user_id)
            
            if not user or not user.is_active:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found or inactive"
                )
        
        # Generate new tokens
        return _create_session(user)
        
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid refresh token: {str(e)}"
        )


def _create_session(user: User) -> AuthSession:
    """Create authentication session with tokens."""
    token_data = {
        "sub": user.id,
        "email": user.email,
    }
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    expires_at = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    
    return AuthSession(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_at=expires_at,
        user=UserResponse(
            id=user.id,
            email=user.email,
            first_name=user.first_name,
            last_name=user.last_name,
        )
    )
