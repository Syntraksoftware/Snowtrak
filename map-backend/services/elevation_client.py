"""HTTP client service for elevation data API (Google Maps)."""
import logging
from typing import List, Tuple, Dict, Any
import httpx

from config import get_config

config = get_config()
logger = logging.getLogger(__name__)


class ElevationClient:
    """Client for fetching elevation data from Google Maps Elevation API."""

    def __init__(self):
        self.api_url = config.GOOGLE_MAPS_ELEVATION_API_URL
        self.api_key = config.GOOGLE_MAPS_API_KEY
        
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
        
        # Google Maps Elevation API accepts locations as pipe-separated lat,lng pairs
        locations = "|".join([f"{lat},{lng}" for lat, lng in coordinates])
        
        params = {
            "locations": locations,
            "key": self.api_key
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.get(self.api_url, params=params)
                response.raise_for_status()
                
                data = response.json()
                
                # Check for API errors
                if data.get("status") != "OK":
                    error_msg = data.get("error_message", "Unknown error")
                    logger.error(f"Google Maps Elevation API error: {error_msg}")
                    raise ValueError(f"API error: {error_msg}")
                
                results = data.get("results", [])
                
                # Convert Google Maps format to standard format
                formatted_results = []
                for result in results:
                    location = result.get("location", {})
                    formatted_results.append({
                        "latitude": location.get("lat"),
                        "longitude": location.get("lng"),
                        "elevation": result.get("elevation")
                    })
                
                logger.info(f"Fetched elevation for {len(formatted_results)} coordinates")
                return formatted_results
                
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
