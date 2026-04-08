import 'dart:io';

import 'package:gpx/gpx.dart';

/// One GPS sample straight from GPX `<trkpt>` before pipeline normalization.
class RawPoint {
  const RawPoint({
    required this.lat,
    required this.lon,
    this.ele,
    this.time,
  });

  final double lat;
  final double lon;

  /// Elevation in meters; `null` when `<ele>` is absent (filled later, e.g. DEM).
  final double? ele;

  /// Timestamp from `<time>`; `null` when omitted.
  final DateTime? time;
}

/// Reads [file] as GPX 1.x and returns all `<trkpt>` rows in document order
/// (tracks → segments → points). Waypoints and routes are ignored.
List<RawPoint> parseGpxFile(File file) {
  final xml = file.readAsStringSync();
  return parseGpxString(xml);
}

/// Same as [parseGpxFile] but from an XML string (easier for small tests).
List<RawPoint> parseGpxString(String xml) {
  final gpx = GpxReader().fromString(xml);
  final out = <RawPoint>[];

  for (final trk in gpx.trks) {
    for (final seg in trk.trksegs) {
      for (final wpt in seg.trkpts) {
        final lat = wpt.lat;
        final lon = wpt.lon;
        if (lat == null || lon == null) {
          continue;
        }
        out.add(
          RawPoint(
            lat: lat,
            lon: lon,
            ele: wpt.ele,
            time: wpt.time,
          ),
        );
      }
    }
  }

  return out;
}
