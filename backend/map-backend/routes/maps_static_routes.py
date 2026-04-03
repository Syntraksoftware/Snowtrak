"""Static map route handlers."""

import logging

from fastapi import APIRouter, Depends, HTTPException, Response, status

from middleware.auth import get_optional_user
from models.maps import StaticMapRequest, StaticMapUrlResponse
from services.static_map_client import get_static_map_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/static", response_model=StaticMapUrlResponse)
async def generate_static_map_url(
    request: StaticMapRequest,
    user_id: str | None = Depends(get_optional_user),
):
    """Generate a URL for a static map image."""
    try:
        client = get_static_map_client()

        path = [tuple(coordinate) for coordinate in request.path] if request.path else None
        markers = [tuple(coordinate) for coordinate in request.markers] if request.markers else None

        url = await client.generate_static_map_url(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom,
            width=request.width,
            height=request.height,
            path=path,
            markers=markers,
        )

        logger.info("Generated static map URL for user: %s", user_id or "anonymous")

        return StaticMapUrlResponse(
            url=url,
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom or 12,
            width=request.width or 600,
            height=request.height or 400,
        )
    except Exception as exception:
        logger.error("Error generating static map URL: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate static map: {str(exception)}",
        ) from None


@router.post("/static/image")
async def fetch_static_map_image(
    request: StaticMapRequest,
    user_id: str | None = Depends(get_optional_user),
):
    """Fetch static map image as binary data."""
    try:
        client = get_static_map_client()

        path = [tuple(coordinate) for coordinate in request.path] if request.path else None
        markers = [tuple(coordinate) for coordinate in request.markers] if request.markers else None

        image_data = await client.fetch_static_map_image(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom,
            width=request.width,
            height=request.height,
            path=path,
            markers=markers,
        )

        logger.info("Fetched static map image for user: %s", user_id or "anonymous")

        return Response(
            content=image_data,
            media_type="image/png",
            headers={"Content-Disposition": "inline; filename=static_map.png"},
        )
    except Exception as exception:
        logger.error("Error fetching static map image: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch static map image: {str(exception)}",
        ) from None


@router.get("/static/simple")
async def get_simple_static_map(
    lat: float,
    lng: float,
    zoom: int | None = 12,
    width: int | None = 600,
    height: int | None = 400,
    user_id: str | None = Depends(get_optional_user),
):
    """Simple GET endpoint for static map URL generation."""
    try:
        client = get_static_map_client()

        url = await client.generate_static_map_url(
            center_lat=lat,
            center_lng=lng,
            zoom=zoom,
            width=width,
            height=height,
        )

        logger.info("Generated simple static map URL for user: %s", user_id or "anonymous")

        return {
            "url": url,
            "center_lat": lat,
            "center_lng": lng,
            "zoom": zoom,
            "width": width,
            "height": height,
        }
    except Exception as exception:
        logger.error("Error generating simple static map: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate static map: {str(exception)}",
        ) from None
