import datetime
from pydantic import BaseModel, Field 
from typing import List, Optional 
from datetime import datetime
from enum import Enum 

# Activity Type Enum 
class ActivityType(str, Enum): 
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
    accuracy: Optional[float] = None 
    speed: Optional[float] = None 
    timestamp: datetime
    
class LocationResponse(BaseModel):
    latitude: float 
    longitude: float
    altitude: float
    accuracy: Optional[float] = None 
    speed: Optional[float] = None 
    timestamp: datetime
    
# Activity Create (for POST requests)
class ActivityCreate(BaseModel):
    type: ActivityType
    name: Optional[str] = None
    description: Optional[str] = None
    distance: float = Field(..., ge=0) 
    # field validation for positive distance, required field
    # (ellipsis: ...) - Indicates this is a required field (no default value)
    duration: int = Field(..., ge=0)
    elevation_gain: float = Field(default=0) # meters
    start_time: datetime
    end_time: datetime
    average_pace: float = Field(default=0, ge=0) # seconds per km 
    max_pace: float = Field(default=0, ge=0) # seconds per km 
    calories: Optional[int] = Field(None, ge=0)
    is_public: bool = True 
    locations: List[LocationCreate] = Field(default=[])
    
    

# Activity Update (for PUT requests - all fields optional)
class ActivityUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_public: Optional[bool] = None

# Activity Response (what we return)
class ActivityResponse(BaseModel):
    id: str
    user_id: str
    type: str
    name: Optional[str] = None
    description: Optional[str] = None
    distance: float
    duration: int
    elevation_gain: float
    start_time: datetime
    end_time: datetime
    average_pace: float
    max_pace: float
    calories: Optional[int] = None
    is_public: bool
    created_at: datetime
    locations: List[LocationResponse] = []