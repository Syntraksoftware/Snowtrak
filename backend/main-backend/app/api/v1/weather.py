"""Weather snapshot routes."""

import logging

from fastapi import APIRouter, HTTPException, status

from app.schemas.weather import WeatherSnapshotRequest, WeatherSnapshotResponse
from app.services.weather import WeatherServiceError, weather_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/weather", tags=["Weather"])


@router.post("/snapshot", response_model=WeatherSnapshotResponse)
def get_weather_snapshot(request: WeatherSnapshotRequest) -> WeatherSnapshotResponse:
    """Build a weather snapshot for the provided activity coordinates."""
    try:
        return weather_service.build_snapshot(request)
    except WeatherServiceError as exception:
        logger.exception("Unable to build weather snapshot: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exception),
        ) from None
