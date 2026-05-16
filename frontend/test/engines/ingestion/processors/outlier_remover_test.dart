import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/outlier_remover.dart';

void main() {
  test('remove drops point when instantaneous speed exceeds 250 km/h', () {
    final points = <RawPoint>[
      RawPoint(lat: 46.0, lon: 8.0, ele: 2000, time: DateTime.utc(2026, 1, 1, 10, 0, 0)),
      // ~1.1 km in 1 second -> ~4000 km/h (impossible for skiing)
      RawPoint(lat: 46.01, lon: 8.0, ele: 2001, time: DateTime.utc(2026, 1, 1, 10, 0, 1)),
      RawPoint(lat: 46.0001, lon: 8.0001, ele: 1999, time: DateTime.utc(2026, 1, 1, 10, 0, 2)),
    ];

    final filtered = remove(points);

    expect(filtered.length, 2);
    expect(filtered[0], points[0]);
    expect(filtered[1], points[2]);
  });

  test('remove drops point when elevation jumps >100m within under 2 seconds', () {
    final points = <RawPoint>[
      RawPoint(lat: 46.0, lon: 8.0, ele: 2000, time: DateTime.utc(2026, 1, 1, 10, 0, 0)),
      RawPoint(lat: 46.00001, lon: 8.00001, ele: 2155, time: DateTime.utc(2026, 1, 1, 10, 0, 1)),
      RawPoint(lat: 46.00002, lon: 8.00002, ele: 2002, time: DateTime.utc(2026, 1, 1, 10, 0, 3)),
    ];

    final filtered = remove(points);

    expect(filtered.length, 2);
    expect(filtered[0], points[0]);
    expect(filtered[1], points[2]);
  });

  test('remove keeps plausible ski points', () {
    final points = <RawPoint>[
      RawPoint(lat: 46.0, lon: 8.0, ele: 2200, time: DateTime.utc(2026, 1, 1, 10, 0, 0)),
      RawPoint(lat: 46.00008, lon: 8.00008, ele: 2198, time: DateTime.utc(2026, 1, 1, 10, 0, 2)),
      RawPoint(lat: 46.00016, lon: 8.00016, ele: 2194, time: DateTime.utc(2026, 1, 1, 10, 0, 4)),
    ];

    final filtered = remove(points);

    expect(filtered.length, 3);
    expect(filtered[0], points[0]);
    expect(filtered[1], points[1]);
    expect(filtered[2], points[2]);
  });

  test('remove keeps points when timestamps are missing (no false speed filtering)', () {
    final points = <RawPoint>[
      const RawPoint(lat: 46.0, lon: 8.0, ele: 2000, time: null),
      const RawPoint(lat: 46.01, lon: 8.01, ele: 1995, time: null),
      const RawPoint(lat: 46.02, lon: 8.02, ele: 1988, time: null),
    ];

    final filtered = remove(points);

    expect(filtered.length, 3);
  });
}
