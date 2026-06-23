"""Route thumbnail renderer — styled dark card with GPS route overlay using Pillow."""

from __future__ import annotations

import io

from PIL import Image, ImageDraw

_BG_TOP    = (20, 20, 28)    # deep blue-black
_BG_BOTTOM = (10, 10, 16)
_GLOW_COLOR = (160, 55, 10)  # dim orange for glow pass
_ROUTE_COLOR = (255, 90, 31)  # app primary orange
_ROUTE_WIDTH = 4
_PADDING = 0.15              # fraction of bbox added on each side


def _gradient_background(width: int, height: int) -> Image.Image:
    """Top-to-bottom gradient from _BG_TOP to _BG_BOTTOM."""
    data = bytearray(width * height * 3)
    for y in range(height):
        t = y / max(height - 1, 1)
        r = int(_BG_TOP[0] + (_BG_BOTTOM[0] - _BG_TOP[0]) * t)
        g = int(_BG_TOP[1] + (_BG_BOTTOM[1] - _BG_TOP[1]) * t)
        b = int(_BG_TOP[2] + (_BG_BOTTOM[2] - _BG_TOP[2]) * t)
        row_start = y * width * 3
        for x in range(width):
            i = row_start + x * 3
            data[i], data[i + 1], data[i + 2] = r, g, b
    return Image.frombytes("RGB", (width, height), bytes(data))


def render_route_png(points: list[tuple[float, float]], width: int, height: int) -> bytes:
    """Return PNG bytes: orange route with glow on a dark gradient background.

    Args:
        points: ordered (lat, lon) pairs.
        width:  output image width in pixels.
        height: output image height in pixels.
    """
    img = _gradient_background(width, height)

    if len(points) >= 2:
        lats = [p[0] for p in points]
        lons = [p[1] for p in points]
        lat_span = (max(lats) - min(lats)) or 1e-4
        lon_span = (max(lons) - min(lons)) or 1e-4
        min_lat = min(lats) - lat_span * _PADDING
        max_lat = max(lats) + lat_span * _PADDING
        min_lon = min(lons) - lon_span * _PADDING
        max_lon = max(lons) + lon_span * _PADDING
        lat_span = max_lat - min_lat
        lon_span = max_lon - min_lon

        # ponytail: linear projection — close enough for ski-resort scale
        def _to_px(lat: float, lon: float) -> tuple[int, int]:
            return (
                int((lon - min_lon) / lon_span * (width - 1)),
                int((max_lat - lat) / lat_span * (height - 1)),
            )

        px = [_to_px(lat, lon) for lat, lon in points]
        draw = ImageDraw.Draw(img)
        draw.line(px, fill=_GLOW_COLOR, width=_ROUTE_WIDTH + 6)  # glow pass
        draw.line(px, fill=_ROUTE_COLOR, width=_ROUTE_WIDTH)      # bright pass

    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()
