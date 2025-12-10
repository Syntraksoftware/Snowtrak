"""
Pydantic schemas for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ===== User Schemas =====

class UserBase(BaseModel):
    """Shared user properties."""
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None


class UserCreate(UserBase):
    """Schema for user registration."""
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """Schema for user profile updates."""
    first_name: Optional[str] = None
    last_name: Optional[str] = None


class UserInDB(UserBase):
    """User as stored in database."""
    id: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_login_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class UserResponse(BaseModel):
    """Public user response (no sensitive data)."""
    id: str
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    
    class Config:
        from_attributes = True


# ===== Auth Schemas =====

class Token(BaseModel):
    """JWT token response."""
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Data extracted from JWT payload."""
    user_id: Optional[str] = None
    email: Optional[str] = None
    token_type: Optional[str] = None  # "access" or "refresh"


class AuthSession(BaseModel):
    """Complete authentication session (matches Flutter AuthSession)."""
    access_token: str
    refresh_token: str
    expires_at: datetime
    user: UserResponse


class LoginRequest(BaseModel):
    """Login credentials."""
    email: str
    password: str


class RefreshTokenRequest(BaseModel):
    """Refresh token request."""
    refresh_token: str


# ===== Generic Responses =====

class MessageResponse(BaseModel):
    """Generic message response."""
    message: str


class ErrorResponse(BaseModel):
    """Error response."""
    error: str
    detail: Optional[str] = None
