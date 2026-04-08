import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/segmentation/vertical_velocity_computer.dart' as vv;
import 'package:syntrak/models/track_point.dart';

void main() {
  test('compute returns per-point vertical velocity with index 0 = 0', () {
    final points = <TrackPoint>[
      TrackPoint(
        lat: 46.0,
        lon: 8.0,
        elevationM: 1000,
        timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0),
        speedKmh: 30,
      ),
      TrackPoint(
        lat: 46.0,
        lon: 8.0,
        elevationM: 999,
        timestamp: DateTime.utc(2026, 1, 1, 10, 0, 1),
        speedKmh: 31,
      ),
      TrackPoint(
        lat: 46.0,
        lon: 8.0,
        elevationM: 995,
        timestamp: DateTime.utc(2026, 1, 1, 10, 0, 2),
        speedKmh: 32,
      ),
      TrackPoint(
        lat: 46.0,
        lon: 8.0,
        elevationM: 994,
        timestamp: DateTime.utc(2026, 1, 1, 10, 0, 3),
        speedKmh: 33,
      ),
    ];

    final values = vv.compute(points);

    expect(values, hasLength(points.length));
    expect(values.first, 0.0);
    expect(values[1], lessThan(0));
    expect(values[2], lessThan(values[1]));
    expect(values[3], lessThan(values[2]));
  });

  test('compute smooths a single spike over 3 points', () {
    final points = <TrackPoint>[
      TrackPoint(lat: 46, lon: 8, elevationM: 1000, timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0), speedKmh: 20),
      TrackPoint(lat: 46, lon: 8, elevationM: 1001, timestamp: DateTime.utc(2026, 1, 1, 10, 0, 1), speedKmh: 20),
      TrackPoint(lat: 46, lon: 8, elevationM: 1101, timestamp: DateTime.utc(2026, 1, 1, 10, 0, 2), speedKmh: 20),
      TrackPoint(lat: 46, lon: 8, elevationM: 1002, timestamp: DateTime.utc(2026, 1, 1, 10, 0, 3), speedKmh: 20),
      TrackPoint(lat: 46, lon: 8, elevationM: 1003, timestamp: DateTime.utc(2026, 1, 1, 10, 0, 4), speedKmh: 20),
    ];

    final values = vv.compute(points);

    expect(values[2].abs(), lessThan(100));
    expect(values[3].abs(), lessThan(values[2].abs()));
  });
}
