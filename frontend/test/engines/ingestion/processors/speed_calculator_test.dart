import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/speed_calculator.dart';

void main() {
  test('compute converts RawPoint to TrackPoint and adds speedKmh', () {
    final points = <RawPoint>[
      RawPoint(lat: 46.8000, lon: 8.2000, ele: 2000, time: DateTime.utc(2026, 1, 1, 10, 0, 0)),
      RawPoint(lat: 46.8001, lon: 8.2001, ele: 1998, time: DateTime.utc(2026, 1, 1, 10, 0, 1)),
      RawPoint(lat: 46.8002, lon: 8.2002, ele: 1995, time: DateTime.utc(2026, 1, 1, 10, 0, 2)),
    ];

    final out = compute(points);

    expect(out.length, points.length);
    expect(out.first.speedKmh, 0.0);
    expect(out[1].speedKmh, greaterThan(0));
    expect(out[2].speedKmh, greaterThan(0));
    expect(out[0].lat, points[0].lat);
    expect(out[0].elevationM, points[0].ele);
  });

  test('compute smooths spikes with trailing 5-point rolling average', () {
    final start = DateTime.utc(2026, 1, 1, 10, 0, 0);
    final points = <RawPoint>[
      RawPoint(lat: 46.8000, lon: 8.2000, ele: 2000, time: start),
      RawPoint(lat: 46.80001, lon: 8.20001, ele: 2000, time: start.add(const Duration(seconds: 1))),
      RawPoint(lat: 46.80002, lon: 8.20002, ele: 2000, time: start.add(const Duration(seconds: 2))),
      RawPoint(lat: 46.81000, lon: 8.21000, ele: 2000, time: start.add(const Duration(seconds: 3))),
      RawPoint(lat: 46.81001, lon: 8.21001, ele: 2000, time: start.add(const Duration(seconds: 4))),
      RawPoint(lat: 46.81002, lon: 8.21002, ele: 2000, time: start.add(const Duration(seconds: 5))),
    ];

    final out = compute(points);

    // The spike should be distributed/smoothed over the rolling window, not just a single peak.
    final spike = out[3].speedKmh;
    final afterSpike = out[4].speedKmh;

    expect(spike, greaterThan(out[2].speedKmh));
    expect(afterSpike, greaterThan(0));
    expect(afterSpike, lessThanOrEqualTo(spike));
  });
}
