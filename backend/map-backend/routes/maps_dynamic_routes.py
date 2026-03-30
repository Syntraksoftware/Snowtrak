"""Dynamic map route handlers."""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import HTMLResponse

from middleware.auth import get_optional_user
from models.maps import DynamicMapHtmlResponse, DynamicMapRequest
from services.dynamic_map_client import get_dynamic_map_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/dynamic", response_model=DynamicMapHtmlResponse)
async def generate_dynamic_map_html(
    request: DynamicMapRequest,
    user_id: Optional[str] = Depends(get_optional_user),
):
    """Generate an interactive map as HTML."""
    try:
        client = get_dynamic_map_client()

        path = [tuple(coordinate) for coordinate in request.path] if request.path else None
        markers = [tuple(coordinate) for coordinate in request.markers] if request.markers else None

        html = client.generate_dynamic_map_html(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom,
            width=request.width,
            height=request.height,
            path=path,
            markers=markers,
            map_id=request.map_id,
            language=request.language,
            region=request.region,
        )

        logger.info("Generated dynamic map HTML for user: %s", user_id or "anonymous")

        return DynamicMapHtmlResponse(
            html=html,
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom or 12,
            width=request.width or 600,
            height=request.height or 400,
        )
    except Exception as exception:
        logger.error("Error generating dynamic map HTML: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dynamic map: {str(exception)}",
        )


@router.post("/dynamic/html")
async def serve_dynamic_map_html(
    request: DynamicMapRequest,
    user_id: Optional[str] = Depends(get_optional_user),
):
    """Serve an interactive map as raw HTML."""
    try:
        client = get_dynamic_map_client()

        path = [tuple(coordinate) for coordinate in request.path] if request.path else None
        markers = [tuple(coordinate) for coordinate in request.markers] if request.markers else None

        html = client.generate_dynamic_map_html(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom,
            width=request.width,
            height=request.height,
            path=path,
            markers=markers,
            map_id=request.map_id,
            language=request.language,
            region=request.region,
        )

        logger.info("Served dynamic map HTML for user: %s", user_id or "anonymous")
        return HTMLResponse(content=html)
    except Exception as exception:
        logger.error("Error serving dynamic map HTML: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dynamic map: {str(exception)}",
        )


@router.get("/dynamic/simple")
async def get_simple_dynamic_map(
    lat: float,
    lng: float,
    zoom: Optional[int] = 12,
    width: Optional[int] = 800,
    height: Optional[int] = 500,
    user_id: Optional[str] = Depends(get_optional_user),
):
    """Simple GET endpoint that returns interactive map HTML."""
    try:
        client = get_dynamic_map_client()

        html = client.generate_dynamic_map_html(
            center_lat=lat,
            center_lng=lng,
            zoom=zoom,
            width=width,
            height=height,
        )

        logger.info("Generated simple dynamic map HTML for user: %s", user_id or "anonymous")
        return HTMLResponse(content=html)
    except Exception as exception:
        logger.error("Error generating simple dynamic map HTML: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dynamic map: {str(exception)}",
        )
