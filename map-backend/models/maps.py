"""Pydantic schemas for static and dynamic map endpoints."""
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


class DynamicMapRequest(BaseModel):
    """Request model for dynamic (interactive) map generation."""
    center_lat: float = Field(..., description="Latitude of map center", ge=-90, le=90)
    center_lng: float = Field(..., description="Longitude of map center", ge=-180, le=180)
    zoom: Optional[int] = Field(None, description="Zoom level", ge=0, le=22)
    width: Optional[int] = Field(None, description="Map width in pixels", ge=1, le=1920)
    height: Optional[int] = Field(None, description="Map height in pixels", ge=1, le=1080)
    path: Optional[List[List[float]]] = Field(None, description="Array of [lat, lng] coordinates for path")
    markers: Optional[List[List[float]]] = Field(None, description="Array of [lat, lng] coordinates for markers")
    map_id: Optional[str] = Field(None, description="Google Maps Map ID for custom styling")
    language: Optional[str] = Field(None, description="Language code (e.g., en, fr, zh)")
    region: Optional[str] = Field(None, description="Region code (e.g., US, CA)")


class DynamicMapHtmlResponse(BaseModel):
    """Response model for dynamic map HTML."""
    html: str
    center_lat: float
    center_lng: float
    zoom: int
    width: int
    height: int
