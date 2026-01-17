"""Pydantic models for Activity Backend."""
from typing import Optional, List
from pydantic import BaseModel, Field


class LocationPoint(BaseModel):
    """GPS location point."""
    lat: float
    lng: float
    elevation: Optional[float] = None
    timestamp: Optional[str] = None  # ISO string


class FrontendLocation(BaseModel):
    """Frontend location schema (as sent/expected by the Flutter app)."""
    id: Optional[str] = None
    activity_id: Optional[str] = None
    latitude: float
    longitude: float
    altitude: Optional[float] = None
    accuracy: Optional[float] = None
    speed: Optional[float] = None
    timestamp: Optional[str] = None  # ISO string


class ActivityCreate(BaseModel):
    """Schema for creating an activity."""
    name: str = Field(..., description="Activity name")
    activity_type: str = Field(..., description="e.g., ski, snowboard")
    gps_path: List[LocationPoint] = Field(default_factory=list)
    duration_seconds: int
    distance_meters: float
    elevation_gain_meters: float
    visibility: str = Field("private", description="private|followers|public")
    description: Optional[str] = None


class FrontendActivityCreate(BaseModel):
    """Schema for creating an activity as sent by the frontend app."""
    type: str
    name: Optional[str] = None
    description: Optional[str] = None
    start_time: str  # ISO 8601
    end_time: str    # ISO 8601
    locations: List[FrontendLocation] = Field(default_factory=list)
    is_public: bool = True


class ActivityUpdate(BaseModel):
    """Schema for updating an activity."""
    name: Optional[str] = None
    description: Optional[str] = None
    visibility: Optional[str] = None


class ActivityResponse(BaseModel):
    """Schema for activity response."""
    id: str
    user_id: str
    name: str
    activity_type: str
    gps_path: List[LocationPoint]
    duration_seconds: int
    distance_meters: float
    elevation_gain_meters: float
    visibility: Optional[str] = None
    description: Optional[str] = None
    created_at: Optional[str] = None


class FrontendActivityResponse(BaseModel):
    """Activity response formatted for the frontend app expectations."""
    id: str
    user_id: str
    type: str
    name: Optional[str] = None
    description: Optional[str] = None
    distance: float
    duration: int
    elevation_gain: float
    start_time: str
    end_time: str
    average_pace: Optional[float] = None
    max_pace: Optional[float] = None
    calories: Optional[int] = None
    is_public: bool
    created_at: Optional[str] = None
    locations: List[FrontendLocation] = Field(default_factory=list)


class ActivitiesListResponse(BaseModel):
    """Schema for activities list response."""
    items: List[ActivityResponse]
    total: int


class CommentCreate(BaseModel):
    """Schema for creating a comment."""
    content: str


class CommentResponse(BaseModel):
    """Schema for comment response."""
    id: Optional[str] = None
    activity_id: str
    user_id: str
    content: str
    created_at: Optional[str] = None


class CommentsListResponse(BaseModel):
    """Schema for comments list response."""
    items: List[CommentResponse]
    total: int


class ToggleKudosResponse(BaseModel):
    """Schema for kudos toggle response."""
    liked: bool


class ShareLinkResponse(BaseModel):
    """Schema for activity share link response."""
    share_token: str
    share_url: str


class DeleteResponse(BaseModel):
    """Schema for delete response."""
    message: str
    deleted_activity_id: Optional[str] = None
