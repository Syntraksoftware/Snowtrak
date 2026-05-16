import 'dart:io';

import 'package:fit_parser/fit_parser.dart';

import 'gpx_parser.dart';

/// Parse a FIT file and extract GPS track points.
///
/// FIT files store position coordinates as "semicircles" (32-bit signed integers).
/// Conversion formula: degrees = semicircles * (180 / 2^31)
///
/// [file] must be a valid FIT binary file.
/// Returns a list of [RawPoint] objects in file order, excluding records without coordinates.
List<RawPoint> parseFitFile(File file) {
  final out = <RawPoint>[];

  try {
    final fitFile = FitFile(path: file.path).parse();

    for (final message in fitFile.dataMessages) {
      // Only process "record" messages (message type 20) which contain GPS samples.
      if (message.definitionMessage?.globalMessageNumber != 20) {
        continue;
      }

      // Build a map of field name -> value for easier lookup.
      Map<String, dynamic> fields = {};
      for (int i = 0; i < message.fields.length; i++) {
        final fieldName = message.fields[i].fieldName;
        final value = message.values[i].value;
        if (fieldName != null) {
          fields[fieldName] = value;
        }
      }

      // Extract position fields (stored as semicircles, null if not present).
      final positionLat = fields['position_lat'];
      final positionLong = fields['position_long'];

      // Skip records without coordinates.
      if (positionLat == null || positionLong == null) {
        continue;
      }

      // Convert to int (FIT parser may return as num/double/int)
      final latSemicircles = (positionLat is int) 
          ? positionLat 
          : (positionLat as num).toInt();
      final lonSemicircles = (positionLong is int) 
          ? positionLong 
          : (positionLong as num).toInt();

      // Convert semicircles to degrees: degrees = semicircles * (180 / 2^31)
      final lat = _semicirclesToDegrees(latSemicircles);
      final lon = _semicirclesToDegrees(lonSemicircles);

      // Extract optional fields.
      final altitudeValue = fields['altitude'];
      final timestampValue = fields['timestamp'];

      // Convert altitude to double if present (may be double or int)
      final ele = altitudeValue != null 
          ? (altitudeValue is num ? altitudeValue.toDouble() : null)
          : null;
      
      // Convert timestamp to DateTime if present (may be double or int)
      DateTime? time;
      if (timestampValue != null && timestampValue is num) {
        final timestampSeconds = timestampValue.toInt();
        time = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000, isUtc: true);
      }

      out.add(
        RawPoint(
          lat: lat,
          lon: lon,
          ele: ele,
          time: time,
        ),
      );
    }
  } catch (e) {
    // If FIT decoding fails, return an empty list (graceful degradation).
    // In production, consider logging the error.
    return [];
  }

  return out;
}

/// Convert FIT semicircle integer to degrees.
///
/// Formula: degrees = semicircles * (180 / 2^31)
/// Where 2^31 = 2147483648
double _semicirclesToDegrees(int semicircles) {
  const semicircToDegrees = 180.0 / 2147483648.0;
  return semicircles * semicircToDegrees;
}
