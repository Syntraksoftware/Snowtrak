from services.gpx_parser import parse_gpx_bytes


def test_parse_gpx_bytes_extracts_track_points():
    xml = b"""<?xml version="1.0" encoding="UTF-8"?>
    <gpx version="1.1" creator="test">
      <trk><trkseg>
        <trkpt lat="46.8" lon="9.8"><ele>2100</ele><time>2024-01-15T10:30:00Z</time></trkpt>
        <trkpt lat="46.801" lon="9.801"><ele>2090</ele><time>2024-01-15T10:31:00Z</time></trkpt>
      </trkseg></trk>
    </gpx>"""

    points = parse_gpx_bytes(xml)

    assert len(points) == 2
    assert points[0]["lat"] == 46.8
    assert points[0]["elevation_m"] == 2100.0
    assert points[0]["speed_kmh"] == 0.0
