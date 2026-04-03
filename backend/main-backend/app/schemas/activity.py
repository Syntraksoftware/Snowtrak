from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, Field


# Activity Type Enum
class ActivityType(StrEnum):
    alpine = "alpine"
    cross_country = "cross_country"
    freestyle = "freestyle"
    backcountry = "backcountry"
    snowboard = "snowboard"
    other = "other"


# Location Schema


class LocationCreate(BaseModel):
    latitude: float
    longitude: float
    altitude: float
    accuracy: float | None = None
    speed: float | None = None
    timestamp: datetime


class LocationResponse(BaseModel):
    latitude: float
    longitude: float
    altitude: float
    accuracy: float | None = None
    speed: float | None = None
    timestamp: datetime


# Activity Create (for POST requests)
class ActivityCreate(BaseModel):
    type: ActivityType
    name: str | None = None
    description: str | None = None
    distance: float = Field(..., ge=0)
    # field validation for positive distance, required field
    # (ellipsis: ...) - Indicates this is a required field (no default value)
    duration: int = Field(..., ge=0)
    elevation_gain: float = Field(default=0)  # meters
    start_time: datetime
    end_time: datetime
    average_pace: float = Field(default=0, ge=0)  # seconds per km
    max_pace: float = Field(default=0, ge=0)  # seconds per km
    calories: int | None = Field(None, ge=0)
    is_public: bool = True
    locations: list[LocationCreate] = Field(default=[])


# Activity Update (for PUT requests - all fields optional)
class ActivityUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    is_public: bool | None = None


# Activity Response (what we return)
class ActivityResponse(BaseModel):
    id: str
    user_id: str
    type: str
    name: str | None = None
    description: str | None = None
    distance: float
    duration: int
    elevation_gain: float
    start_time: datetime
    end_time: datetime
    average_pace: float
    max_pace: float
    calories: int | None = None
    is_public: bool
    created_at: datetime
    locations: list[LocationResponse] = []
