import 'package:syntrak/core/constants/trail_detection_thresholds.dart';
import 'package:syntrak/models/track_point.dart';

enum PointState {
  descent,
  lift,
  flat,
  pause,
}

/// Classifies a point using vertical velocity and speed.
///
/// The pause rule depends on how long speed has remained below the pause speed
/// threshold. Callers can pass [lowSpeedDurationSeconds] when that context is
/// available; otherwise it defaults to zero.
PointState classify(
  TrackPoint pt,
  double vv, {
  double lowSpeedDurationSeconds = 0.0,
}) {
  if (pt.speedKmh < pauseSpeedKmh && lowSpeedDurationSeconds > pauseMinSeconds) {
    return PointState.pause;
  }

  if (vv < descentVvThreshold) {
    return PointState.descent;
  }

  if (vv > liftVvThreshold) {
    return PointState.lift;
  }

  return PointState.flat;
}
