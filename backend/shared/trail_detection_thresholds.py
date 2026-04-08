"""
Trail / segment detection tuning.

Mirror of `frontend/lib/core/constants/trail_detection_thresholds.dart`.
Change values in one place only by editing both files together (or generating from a single manifest later).

when offline, the Dart files on the user's phone are used to configure the app, and when the app connects to the server, the configuration values from the server override the local ones.
this file is used to configure the app when connected to the server.
"""

from typing import Final

# Vertical velocity (m/s): descending
DESCENT_VV_THRESHOLD: Final[float] = -0.5

# Vertical velocity (m/s): lift / uphill transport
LIFT_VV_THRESHOLD: Final[float] = 0.3

# Ground speed (km/h): pause candidate band
PAUSE_SPEED_KMH: Final[float] = 2.0

# Seconds at low speed before classifying a pause
PAUSE_MIN_SECONDS: Final[int] = 8

# Ramer–Douglas–Peucker tolerance (same units as input coordinates; geo paths use degrees)
RDP_EPSILON: Final[float] = 0.0001

# Meters: max distance from sample to trail geometry for a name match
TRAIL_MATCH_RADIUS_M: Final[float] = 50.0

__all__ = [
    "DESCENT_VV_THRESHOLD",
    "LIFT_VV_THRESHOLD",
    "PAUSE_SPEED_KMH",
    "PAUSE_MIN_SECONDS",
    "RDP_EPSILON",
    "TRAIL_MATCH_RADIUS_M",
]
