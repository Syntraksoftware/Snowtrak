import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/fit_parser.dart';

void main() {
  test('parseFitFile reads minimal_activity.fit and extracts RawPoints', () {
    // `flutter test` uses the package root as working directory.
    final fixture = File('test/engines/ingestion/parsers/fixtures/minimal_activity.fit');

    expect(fixture.existsSync(), isTrue, reason: 'fixture minimal_activity.fit must exist');

    final points = parseFitFile(fixture);

    // Verify that we got at least one point from the fixture.
    expect(points, isNotEmpty, reason: 'fixture should contain at least one GPS record');

    // Verify each point has valid coordinates.
    for (final point in points) {
      expect(point.lat, isNotNull);
      expect(point.lon, isNotNull);
      expect(point.lat, greaterThanOrEqualTo(-90.0));
      expect(point.lat, lessThanOrEqualTo(90.0));
      expect(point.lon, greaterThanOrEqualTo(-180.0));
      expect(point.lon, lessThanOrEqualTo(180.0));
    }
  });

  test('semicircles to degrees conversion: coordinates are in valid range', () {
    // Test that parsed coordinates fall within valid lat/lon ranges.
    // This indirectly validates the semicircles → degrees conversion.
    final fixture = File('test/engines/ingestion/parsers/fixtures/minimal_activity.fit');
    final points = parseFitFile(fixture);

    if (points.isNotEmpty) {
      final first = points.first;
      // Verify conversion resulted in reasonable latitude/longitude ranges.
      expect(first.lat.abs(), lessThanOrEqualTo(90.0));
      expect(first.lon.abs(), lessThanOrEqualTo(180.0));
    }
  });

  test('RawPoint contains lat, lon, and optional ele, time', () {
    final fixture = File('test/engines/ingestion/parsers/fixtures/minimal_activity.fit');
    final points = parseFitFile(fixture);

    expect(points, isNotEmpty);

    final firstPoint = points.first;

    // These must always be present.
    expect(firstPoint.lat, isNotNull);
    expect(firstPoint.lon, isNotNull);

    // These may be null depending on the FIT file content.
    // Just verify they're either null or have reasonable values.
    if (firstPoint.ele != null) {
      expect(firstPoint.ele, greaterThan(-500.0)); // Below sea level but reasonable
      expect(firstPoint.ele, lessThan(9000.0)); // Below highest mountain
    }

    if (firstPoint.time != null) {
      // Verify it's a reasonable timestamp (not way in the past or future).
      final now = DateTime.now().toUtc();
      expect(firstPoint.time!.year, greaterThanOrEqualTo(2000));
      expect(firstPoint.time!.year, lessThanOrEqualTo(now.year + 1));
    }
  });

  test('RawPoint objects preserve order from FIT file', () {
    final fixture = File('test/engines/ingestion/parsers/fixtures/minimal_activity.fit');
    final points = parseFitFile(fixture);

    // If we have multiple points, verify they're in a sensible order
    // (timestamps generally increase, or at least don't drastically jump).
    if (points.length > 1) {
      for (var i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];

        // If both have timestamps, the current should be >= previous.
        if (prev.time != null && curr.time != null) {
          expect(curr.time!.isAfter(prev.time!) || curr.time == prev.time, isTrue);
        }
      }
    }
  });
}
