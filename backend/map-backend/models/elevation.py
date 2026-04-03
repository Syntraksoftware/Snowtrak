"""Pydantic schemas for elevation endpoints."""

from pydantic import BaseModel, Field


class CoordinatePoint(BaseModel):
    """Coordinate point model."""

    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class ElevationRequest(BaseModel):
    """Request model for elevation lookup."""

    locations: list[CoordinatePoint] = Field(..., min_length=1, max_length=1000)


class ElevationResult(BaseModel):
    """Result model for a single elevation point."""

    latitude: float
    longitude: float
    elevation: float


class ElevationResponse(BaseModel):
    """Response model for elevation lookup."""

    results: list[ElevationResult]
    count: int
