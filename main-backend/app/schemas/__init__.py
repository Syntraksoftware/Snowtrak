"""
Pydantic schemas for request/response validation.
"""
from pydantic import BaseModel, Field, EmailStr, ConfigDict
from typing import Optional
from datetime import datetime


# User Schemas 

class UserBase(BaseModel):
    """Shared user properties."""
    email: EmailStr
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
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_login_at: Optional[datetime] = None


class UserResponse(BaseModel):
    """Public user response (no sensitive data)."""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None


# Auth Schemas 

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
    detail: Optional[str] = None

