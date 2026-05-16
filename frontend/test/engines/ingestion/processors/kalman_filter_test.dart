import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/kalman_filter.dart' as kalman;

void main() {
  test('apply smooths jittery track while preserving point count', () {
    final points = _jitteryFixtureTrack();

    final rawJitter = _roughness(points);
    final smoothed = kalman.apply(points);
    final smoothJitter = _roughness(smoothed);

    expect(smoothed.length, points.length);
    expect(smoothJitter, lessThan(rawJitter));

    // Expect at least 25% roughness reduction on this synthetic jitter fixture.
    expect(smoothJitter, lessThan(rawJitter * 0.75));
  });
}

List<RawPoint> _jitteryFixtureTrack() {
  final out = <RawPoint>[];
  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);

  for (var i = 0; i < 40; i++) {
    final baseLat = 46.800000 + (i * 0.00008);
    final baseLon = 8.200000 + (i * 0.00010);

    // Alternating and periodic noise to emulate GPS jitter on a mostly linear ski line.
    final latNoise = (i.isEven ? 1 : -1) * 0.00003 + ((i % 3) - 1) * 0.00001;
    final lonNoise = (i.isEven ? -1 : 1) * 0.000028 + ((i % 4) - 1.5) * 0.000008;

    out.add(
      RawPoint(
        lat: baseLat + latNoise,
        lon: baseLon + lonNoise,
        time: start.add(Duration(seconds: i)),
      ),
    );
  }

  return out;
}

// A simple jitter metric: sum of squared second differences (discrete curvature proxy).
double _roughness(List<RawPoint> points) {
  if (points.length < 3) {
    return 0.0;
  }

  var sum = 0.0;
  for (var i = 1; i < points.length - 1; i++) {
    final latSecondDiff = points[i + 1].lat - 2 * points[i].lat + points[i - 1].lat;
    final lonSecondDiff = points[i + 1].lon - 2 * points[i].lon + points[i - 1].lon;
    sum += latSecondDiff * latSecondDiff + lonSecondDiff * lonSecondDiff;
  }
  return sum;
}
