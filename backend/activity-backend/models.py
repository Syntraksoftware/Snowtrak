"""Pydantic models for Activity Backend."""

from pydantic import BaseModel, Field


class LocationPoint(BaseModel):
    """GPS location point."""

    lat: float
    lng: float
    elevation: float | None = None
    timestamp: str | None = None  # ISO string


class FrontendLocation(BaseModel):
    """Frontend location schema (as sent/expected by the Flutter app)."""

    id: str | None = None
    activity_id: str | None = None
    latitude: float
    longitude: float
    altitude: float | None = None
    accuracy: float | None = None
    speed: float | None = None
    timestamp: str | None = None  # ISO string


class ActivityCreate(BaseModel):
    """Schema for creating an activity."""

    name: str = Field(..., description="Activity name")
    activity_type: str = Field(..., description="e.g., ski, snowboard")
    gps_path: list[LocationPoint] = Field(default_factory=list)
    duration_seconds: int
    distance_meters: float
    elevation_gain_meters: float
    visibility: str = Field("private", description="private|followers|public")
    description: str | None = None


class FrontendActivityCreate(BaseModel):
    """Schema for creating an activity as sent by the frontend app."""

    type: str
    name: str | None = None
    description: str | None = None
    start_time: str  # ISO 8601
    end_time: str  # ISO 8601
    locations: list[FrontendLocation] = Field(default_factory=list)
    is_public: bool = True


class ActivityUpdate(BaseModel):
    """Schema for updating an activity."""

    name: str | None = None
    description: str | None = None
    visibility: str | None = None


class FrontendActivityUpdate(BaseModel):
    """Frontend update payload (maps is_public -> visibility)."""

    name: str | None = None
    description: str | None = None
    is_public: bool | None = None


class ActivityResponse(BaseModel):
    """Schema for activity response."""

    id: str
    user_id: str
    name: str
    activity_type: str
    gps_path: list[LocationPoint]
    duration_seconds: int
    distance_meters: float
    elevation_gain_meters: float
    visibility: str | None = None
    description: str | None = None
    created_at: str | None = None


class FrontendActivityResponse(BaseModel):
    """Activity response formatted for the frontend app expectations."""

    id: str
    user_id: str
    type: str
    name: str | None = None
    description: str | None = None
    distance: float
    duration: int
    elevation_gain: float
    start_time: str
    end_time: str
    average_pace: float | None = None
    max_pace: float | None = None
    calories: int | None = None
    is_public: bool
    created_at: str | None = None
    locations: list[FrontendLocation] = Field(default_factory=list)


class ActivitiesListResponse(BaseModel):
    """Schema for activities list response."""

    items: list[ActivityResponse]
    total: int


class CommentCreate(BaseModel):
    """Schema for creating a comment."""

    content: str


class CommentResponse(BaseModel):
    """Schema for comment response."""

    id: str | None = None
    activity_id: str
    user_id: str
    content: str
    created_at: str | None = None


class CommentsListResponse(BaseModel):
    """Schema for comments list response."""

    items: list[CommentResponse]
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
    deleted_activity_id: str | None = None
