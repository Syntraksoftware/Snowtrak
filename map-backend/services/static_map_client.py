"""HTTP client service for static map API (Google Maps)."""
import logging
from typing import Optional, List, Tuple
import httpx

from config import get_config

config = get_config()
logger = logging.getLogger(__name__)


class StaticMapClient:
    """Client for generating static map images using Google Maps Static API."""

    def __init__(self):
        self.api_key = config.GOOGLE_MAPS_API_KEY
        self.base_url = config.GOOGLE_MAPS_STATIC_API_URL
        
    async def generate_static_map_url(
        self,
        center_lat: float,
        center_lng: float,
        zoom: Optional[int] = None,
        width: Optional[int] = None,
        height: Optional[int] = None,
        path: Optional[List[Tuple[float, float]]] = None,
        markers: Optional[List[Tuple[float, float]]] = None,
    ) -> str:
        """
        Generate a static map image URL using Google Maps Static API.
        
        Args:
            center_lat: Latitude of map center
            center_lng: Longitude of map center
            zoom: Zoom level (default from config)
            width: Image width in pixels (default from config)
            height: Image height in pixels (default from config)
            path: Optional list of (lat, lng) coordinates for path overlay
            markers: Optional list of (lat, lng) coordinates for markers
            
        Returns:
            URL string for the static map image
        """
        zoom = zoom or config.STATIC_MAP_ZOOM
        width = width or config.STATIC_MAP_WIDTH
        height = height or config.STATIC_MAP_HEIGHT
        
        # Build query parameters
        params = {
            "center": f"{center_lat},{center_lng}",
            "zoom": str(zoom),
            "size": f"{width}x{height}",
            "key": self.api_key,
            "style": "feature:all|element:labels|visibility:off"
        }
        
        # Add markers if provided
        if markers and len(markers) > 0:
            marker_strings = [f"{lat},{lng}" for lat, lng in markers]
            params["markers"] = "|".join(marker_strings)
        
        # Add path if provided
        if path and len(path) > 0:
            path_coords = "|".join([f"{lat},{lng}" for lat, lng in path])
            params["path"] = f"color:0x3b82f6|weight:2|{path_coords}"
        
        # Build URL
        param_str = "&".join([f"{k}={v}" for k, v in params.items()])
        final_url = f"{self.base_url}?{param_str}"
        
        logger.info(f"Generated static map URL for center ({center_lat}, {center_lng})")
        return final_url
    
    async def fetch_static_map_image(
        self,
        center_lat: float,
        center_lng: float,
        zoom: Optional[int] = None,
        width: Optional[int] = None,
        height: Optional[int] = None,
        path: Optional[List[Tuple[float, float]]] = None,
        markers: Optional[List[Tuple[float, float]]] = None,
    ) -> bytes:
        """
        Fetch static map image as bytes.
        
        Returns:
            Image data as bytes
        """
        url = await self.generate_static_map_url(
            center_lat, center_lng, zoom, width, height, path, markers
        )
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.get(url)
                response.raise_for_status()
                return response.content
            except httpx.HTTPError as e:
                logger.error(f"Failed to fetch static map image: {e}")
                raise


# Global instance
_static_map_client: Optional[StaticMapClient] = None


def get_static_map_client() -> StaticMapClient:
    """Get or create the global StaticMapClient instance."""
    global _static_map_client
    if _static_map_client is None:
        _static_map_client = StaticMapClient()
    return _static_map_client
