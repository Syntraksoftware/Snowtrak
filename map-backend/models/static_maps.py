"""Pydantic schemas for static map endpoints."""
from typing import Optional, List
from pydantic import BaseModel, Field


class StaticMapRequest(BaseModel):
    """Request model for static map generation."""
    center_lat: float = Field(..., description="Latitude of map center", ge=-90, le=90)
    center_lng: float = Field(..., description="Longitude of map center", ge=-180, le=180)
    zoom: Optional[int] = Field(None, description="Zoom level", ge=0, le=22)
    width: Optional[int] = Field(None, description="Image width in pixels", ge=1, le=1280)
    height: Optional[int] = Field(None, description="Image height in pixels", ge=1, le=1280)
    path: Optional[List[List[float]]] = Field(None, description="Array of [lat, lng] coordinates for path")
    markers: Optional[List[List[float]]] = Field(None, description="Array of [lat, lng] coordinates for markers")


class StaticMapUrlResponse(BaseModel):
    """Response model for static map URL."""
    url: str
    center_lat: float
    center_lng: float
    zoom: int
    width: int
    height: int
