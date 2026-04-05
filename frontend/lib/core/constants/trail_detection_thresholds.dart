/// Trail / segment detection tuning. Keep in sync with
/// `backend/shared/trail_detection_thresholds.py`.
/// configurable after deployment 

library trail_detection_thresholds;

/// Vertical velocity (m/s) below which motion counts as descending.
const descentVvThreshold = -0.5;

/// Vertical velocity (m/s) above which motion counts as lift / uphill transport.
const liftVvThreshold = 0.3;

/// Ground speed (km/h) at or below which a pause can be considered.
const pauseSpeedKmh = 2.0;

/// Minimum duration (seconds) at low speed before classifying a pause.
const pauseMinSeconds = 8;

/// Ramer–Douglas–Peucker tolerance (same units as input coordinates; geo paths use degrees).
const rdpEpsilon = 0.0001;

/// Max distance (meters) from a track sample to a trail polyline for a name match.

const trailMatchRadiusM = 50.0;
