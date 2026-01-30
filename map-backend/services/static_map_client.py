"""HTTP client service for static map API (Mapbox)."""
import logging
from typing import Optional, List, Tuple
import httpx

from config import get_config

config = get_config()
logger = logging.getLogger(__name__)


class StaticMapClient:
    """Client for generating static map images using Mapbox."""

    def __init__(self):
        self.access_token = config.MAPBOX_ACCESS_TOKEN
        self.base_url = "https://api.mapbox.com/styles/v1"
        self.default_style = "mapbox/outdoors-v12"
        
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
        Generate a static map image URL using Mapbox Static Images API.
        
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
        
        # Build overlay string for path and markers
        overlay = ""
        
        if path and len(path) > 0:
            # Create path overlay: path-{strokeWidth}+{strokeColor}-{opacity}({coordinates})
            path_coords = ",".join([f"{lng},{lat}" for lat, lng in path])
            overlay += f"path-2+3b82f6-0.8({path_coords}),"
        
        if markers and len(markers) > 0:
            # Create markers overlay
            for lat, lng in markers:
                overlay += f"pin-s+3b82f6({lng},{lat}),"
        
        # Remove trailing comma
        overlay = overlay.rstrip(",")
        
        # Build URL
        # Format: /styles/v1/{style}/static/{overlay}/{lon},{lat},{zoom}/{width}x{height}
        if overlay:
            url = (
                f"{self.base_url}/{self.default_style}/static/"
                f"{overlay}/{center_lng},{center_lat},{zoom}/{width}x{height}"
            )
        else:
            url = (
                f"{self.base_url}/{self.default_style}/static/"
                f"{center_lng},{center_lat},{zoom}/{width}x{height}"
            )
        
        # Add parameters
        params = {
            "access_token": self.access_token,
            "attribution": "false",
            "logo": "false"
        }
        
        param_str = "&".join([f"{k}={v}" for k, v in params.items()])
        final_url = f"{url}?{param_str}"
        
        logger.info(f"Generated static map URL: {final_url[:100]}...")
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
