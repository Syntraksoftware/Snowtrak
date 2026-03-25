"""Routes for static and dynamic map generation."""
import logging
from typing import Optional
from fastapi import APIRouter, HTTPException, status, Depends, Response
from fastapi.responses import HTMLResponse

from middleware.auth import get_optional_user
from services.static_map_client import get_static_map_client
from services.dynamic_map_client import get_dynamic_map_client
from models.maps import (
    StaticMapRequest,
    StaticMapUrlResponse,
    DynamicMapRequest,
    DynamicMapHtmlResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/maps", tags=["maps"])


@router.post("/static", response_model=StaticMapUrlResponse)
async def generate_static_map_url(
    request: StaticMapRequest,
    user_id: Optional[str] = Depends(get_optional_user)
):
    """
    Generate a URL for a static map image.
    
    Authentication is optional. If authenticated, usage can be tracked.
    """
    try:
        client = get_static_map_client()
        
        # Convert path and markers from [[lat, lng], ...] to [(lat, lng), ...]
        path = [tuple(coord) for coord in request.path] if request.path else None
        markers = [tuple(coord) for coord in request.markers] if request.markers else None
        
        url = await client.generate_static_map_url(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom,
            width=request.width,
            height=request.height,
            path=path,
            markers=markers
        )
        
        logger.info(f"Generated static map URL for user: {user_id or 'anonymous'}")
        
        return StaticMapUrlResponse(
            url=url,
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom or 12,
            width=request.width or 600,
            height=request.height or 400
        )
    except Exception as e:
        logger.error(f"Error generating static map URL: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate static map: {str(e)}"
        )


@router.post("/static/image")
async def fetch_static_map_image(
    request: StaticMapRequest,
    user_id: Optional[str] = Depends(get_optional_user)
):
    """
    Fetch static map image as binary data.
    
    Returns the image directly with appropriate content-type header.
    Authentication is optional.
    """
    try:
        client = get_static_map_client()
        
        # Convert path and markers from [[lat, lng], ...] to [(lat, lng), ...]
        path = [tuple(coord) for coord in request.path] if request.path else None
        markers = [tuple(coord) for coord in request.markers] if request.markers else None
        
        image_data = await client.fetch_static_map_image(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom,
            width=request.width,
            height=request.height,
            path=path,
            markers=markers
        )
        
        logger.info(f"Fetched static map image for user: {user_id or 'anonymous'}")
        
        return Response(
            content=image_data,
            media_type="image/png",
            headers={
                "Content-Disposition": f"inline; filename=static_map.png"
            }
        )
    except Exception as e:
        logger.error(f"Error fetching static map image: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch static map image: {str(e)}"
        )


@router.get("/static/simple")
async def get_simple_static_map(
    lat: float,
    lng: float,
    zoom: Optional[int] = 12,
    width: Optional[int] = 600,
    height: Optional[int] = 400,
    user_id: Optional[str] = Depends(get_optional_user)
):
    """
    Simple GET endpoint for static map URL generation.
    
    Query parameters:
    - lat: Latitude
    - lng: Longitude
    - zoom: Zoom level (default: 12)
    - width: Image width (default: 600)
    - height: Image height (default: 400)
    """
    try:
        client = get_static_map_client()
        
        url = await client.generate_static_map_url(
            center_lat=lat,
            center_lng=lng,
            zoom=zoom,
            width=width,
            height=height
        )
        
        logger.info(f"Generated simple static map URL for user: {user_id or 'anonymous'}")
        
        return {
            "url": url,
            "center_lat": lat,
            "center_lng": lng,
            "zoom": zoom,
            "width": width,
            "height": height
        }
    except Exception as e:
        logger.error(f"Error generating simple static map: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate static map: {str(e)}"
        )


@router.post("/dynamic", response_model=DynamicMapHtmlResponse)
async def generate_dynamic_map_html(
    request: DynamicMapRequest,
    user_id: Optional[str] = Depends(get_optional_user)
):
    """
    Generate an interactive map as HTML.

    The response contains an HTML document with Google Maps JS API.
    """
    try:
        client = get_dynamic_map_client()

        path = [tuple(coord) for coord in request.path] if request.path else None
        markers = [tuple(coord) for coord in request.markers] if request.markers else None

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

        logger.info(f"Generated dynamic map HTML for user: {user_id or 'anonymous'}")

        return DynamicMapHtmlResponse(
            html=html,
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            zoom=request.zoom or 12,
            width=request.width or 600,
            height=request.height or 400,
        )
    except Exception as e:
        logger.error(f"Error generating dynamic map HTML: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dynamic map: {str(e)}"
        )


@router.post("/dynamic/html")
async def serve_dynamic_map_html(
    request: DynamicMapRequest,
    user_id: Optional[str] = Depends(get_optional_user)
):
    """
    Serve an interactive map as raw HTML.
    """
    try:
        client = get_dynamic_map_client()

        path = [tuple(coord) for coord in request.path] if request.path else None
        markers = [tuple(coord) for coord in request.markers] if request.markers else None

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

        logger.info(f"Served dynamic map HTML for user: {user_id or 'anonymous'}")

        return HTMLResponse(content=html)
    except Exception as e:
        logger.error(f"Error serving dynamic map HTML: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dynamic map: {str(e)}"
        )


@router.get("/dynamic/simple")
async def get_simple_dynamic_map(
    lat: float,
    lng: float,
    zoom: Optional[int] = 12,
    width: Optional[int] = 800,
    height: Optional[int] = 500,
    user_id: Optional[str] = Depends(get_optional_user)
):
    """
    Simple GET endpoint that returns interactive map HTML.
    """
    try:
        client = get_dynamic_map_client()

        html = client.generate_dynamic_map_html(
            center_lat=lat,
            center_lng=lng,
            zoom=zoom,
            width=width,
            height=height,
        )

        logger.info(f"Generated simple dynamic map HTML for user: {user_id or 'anonymous'}")

        return HTMLResponse(content=html)
    except Exception as e:
        logger.error(f"Error generating simple dynamic map HTML: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dynamic map: {str(e)}"
        )
