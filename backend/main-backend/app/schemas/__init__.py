"""
Pydantic schemas for request/response validation.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.schemas.activity import (
    ActivityCreate as ActivityCreate,
    ActivityResponse as ActivityResponse,
    ActivityType as ActivityType,
    ActivityUpdate as ActivityUpdate,
    LocationCreate as LocationCreate,
    LocationResponse as LocationResponse,
)

# User Schemas


class UserBase(BaseModel):
    """Shared user properties."""

    email: EmailStr
    first_name: str | None = None
    last_name: str | None = None


class UserCreate(UserBase):
    """Schema for user registration."""

    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """Schema for user profile updates."""

    first_name: str | None = None
    last_name: str | None = None


class UserInDB(UserBase):
    """User as stored in database."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime | None = None
    last_login_at: datetime | None = None


class UserResponse(BaseModel):
    """Public user response (no sensitive data)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    first_name: str | None = None
    last_name: str | None = None


# Profile Schemas


class ProfileBase(BaseModel):
    """Shared profile properties."""

    full_name: str | None = None
    username: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    push_token: str | None = None
    ski_level: str | None = None
    home: str | None = None


class ProfileUpdate(BaseModel):
    """Schema for profile updates."""

    full_name: str | None = None
    username: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    push_token: str | None = None
    ski_level: str | None = None
    home: str | None = None


class ProfileResponse(BaseModel):
    """Profile data returned to API clients (frontend)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    full_name: str | None = None
    username: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    push_token: str | None = None
    ski_level: str | None = None
    home: str | None = None
    created_at: datetime
    updated_at: datetime | None = None


# Auth Schemas


class Token(BaseModel):
    """JWT token response."""

    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Data extracted from JWT payload."""

    user_id: str | None = None
    email: str | None = None
    token_type: str | None = None  # "access" or "refresh"


class AuthSession(BaseModel):
    """Complete authentication session (matches Flutter AuthSession)."""

    access_token: str
    refresh_token: str
    expires_at: datetime
    user: UserResponse


class LoginRequest(BaseModel):
    """Login credentials."""

    email: EmailStr
    password: str


class RefreshTokenRequest(BaseModel):
    """Refresh token request."""

    refresh_token: str


#  Generic Responses


class MessageResponse(BaseModel):
    """Generic message response."""

    message: str


class ErrorResponse(BaseModel):
    """Error response."""

    error: str
    detail: str | None = None
