"""Service for generating dynamic (interactive) map HTML using Google Maps JS API."""

import json
import logging

from config import get_config

config = get_config()
logger = logging.getLogger(__name__)


class DynamicMapClient:
    """Client for generating interactive map HTML."""

    def __init__(self):
        self.api_key = config.GOOGLE_MAPS_API_KEY
        self.js_api_url = config.GOOGLE_MAPS_JS_API_URL
        self.default_map_id = config.GOOGLE_MAPS_MAP_ID

    def generate_dynamic_map_html(
        self,
        center_lat: float,
        center_lng: float,
        zoom: int | None = None,
        width: int | None = None,
        height: int | None = None,
        path: list[tuple[float, float]] | None = None,
        markers: list[tuple[float, float]] | None = None,
        map_id: str | None = None,
        language: str | None = None,
        region: str | None = None,
    ) -> str:
        """
        Generate an interactive Google Maps HTML document.
        """
        zoom = zoom or getattr(config, "DYNAMIC_MAP_ZOOM", config.STATIC_MAP_ZOOM)
        width = width or getattr(config, "DYNAMIC_MAP_WIDTH", config.STATIC_MAP_WIDTH)
        height = height or getattr(config, "DYNAMIC_MAP_HEIGHT", config.STATIC_MAP_HEIGHT)
        resolved_map_id = map_id or self.default_map_id

        markers = markers or []
        path = path or []

        markers_json = json.dumps([{"lat": lat, "lng": lng} for lat, lng in markers])
        path_json = json.dumps([{"lat": lat, "lng": lng} for lat, lng in path])

        query_params = {
            "key": self.api_key,
            "callback": "initMap",
        }
        if language:
            query_params["language"] = language
        if region:
            query_params["region"] = region

        query_string = "&".join([f"{k}={v}" for k, v in query_params.items()])
        script_src = f"{self.js_api_url}?{query_string}"

        map_id_line = f"mapId: '{resolved_map_id}'," if resolved_map_id else ""

        html = f"""<!DOCTYPE html>
<html lang=\"en\">
  <head>
    <meta charset=\"utf-8\" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
    <title>Interactive Map</title>
    <style>
      html, body {{ height: 100%; margin: 0; padding: 0; }}
      #map {{ width: {width}px; height: {height}px; }}
    </style>
  </head>
  <body>
    <div id=\"map\"></div>
    <script>
      const markers = {markers_json};
      const path = {path_json};

      function initMap() {{
        const center = {{ lat: {center_lat}, lng: {center_lng} }};
        const map = new google.maps.Map(document.getElementById('map'), {{
          center,
          zoom: {zoom},
          {map_id_line}
        }});

        markers.forEach((marker) => {{
          new google.maps.Marker({{
            position: marker,
            map,
          }});
        }});

        if (path.length > 1) {{
          const polyline = new google.maps.Polyline({{
            path,
            geodesic: true,
            strokeColor: '#3b82f6',
            strokeOpacity: 0.9,
            strokeWeight: 3,
          }});
          polyline.setMap(map);
        }}
      }}
    </script>
    <script src=\"{script_src}\" async defer></script>
  </body>
</html>"""

        logger.info("Generated dynamic map HTML")
        return html


_dynamic_map_client: DynamicMapClient | None = None


def get_dynamic_map_client() -> DynamicMapClient:
    """Get or create the global DynamicMapClient instance."""
    global _dynamic_map_client
    if _dynamic_map_client is None:
        _dynamic_map_client = DynamicMapClient()
    return _dynamic_map_client
