"""Routes for static map image generation."""
import logging
from typing import Optional
from fastapi import APIRouter, HTTPException, status, Depends, Response

from middleware.auth import get_current_user, get_optional_user
from services.static_map_client import get_static_map_client
from models.static_maps import StaticMapRequest, StaticMapUrlResponse

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
