import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';

void main() {
  test('parseGpxFile extracts trkpts: lat, lon, ele, time', () {
    // `flutter test` uses the package root as working directory.
    final fixture = File('test/engines/ingestion/parsers/fixtures/sample_track.gpx');

    expect(fixture.existsSync(), isTrue, reason: 'fixture must exist');

    final points = parseGpxFile(fixture);

    expect(points, hasLength(3));

    expect(points[0].lat, 47.5);
    expect(points[0].lon, 8.5);
    expect(points[0].ele, 1200.5);
    expect(points[0].time, DateTime.utc(2026, 1, 1, 10, 0, 0));

    expect(points[1].lat, 47.51);
    expect(points[1].lon, 8.51);
    expect(points[1].ele, isNull);
    expect(points[1].time, DateTime.utc(2026, 1, 1, 10, 1, 0));

    expect(points[2].lat, 47.52);
    expect(points[2].lon, 8.52);
    expect(points[2].ele, 1180.0);
    expect(points[2].time, DateTime.utc(2026, 1, 1, 10, 2, 0));
  });

  test('parseGpxString returns empty list when no tracks', () {
    const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="empty" xmlns="http://www.topografix.com/GPX/1/1">
</gpx>''';
    expect(parseGpxString(xml), isEmpty);
  });
}
