"""HTTP client service for elevation data API."""
import logging
from typing import List, Tuple, Dict, Any
import httpx

from config import get_config

config = get_config()
logger = logging.getLogger(__name__)


class ElevationClient:
    """Client for fetching elevation data from Open Elevation API."""

    def __init__(self):
        self.api_url = config.OPEN_ELEVATION_API_URL
        
    async def get_elevation(
        self,
        coordinates: List[Tuple[float, float]]
    ) -> List[Dict[str, Any]]:
        """
        Get elevation data for a list of coordinates.
        
        Args:
            coordinates: List of (latitude, longitude) tuples
            
        Returns:
            List of dicts with 'latitude', 'longitude', and 'elevation' keys
        """
        if not coordinates:
            return []
        
        # Convert coordinates to API format
        locations = [
            {"latitude": lat, "longitude": lng}
            for lat, lng in coordinates
        ]
        
        payload = {"locations": locations}
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(self.api_url, json=payload)
                response.raise_for_status()
                
                data = response.json()
                results = data.get("results", [])
                
                logger.info(f"Fetched elevation for {len(results)} coordinates")
                return results
                
            except httpx.HTTPError as e:
                logger.error(f"Failed to fetch elevation data: {e}")
                raise
            except Exception as e:
                logger.error(f"Unexpected error fetching elevation: {e}")
                raise


# Global instance
_elevation_client = None


def get_elevation_client() -> ElevationClient:
    """Get or create the global ElevationClient instance."""
    global _elevation_client
    if _elevation_client is None:
        _elevation_client = ElevationClient()
    return _elevation_client
