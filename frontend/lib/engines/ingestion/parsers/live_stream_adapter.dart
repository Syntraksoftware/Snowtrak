import 'dart:async';
import 'dart:collection';

import 'package:geolocator/geolocator.dart';

import 'gpx_parser.dart';

typedef PositionStreamFactory = Stream<Position> Function(LocationSettings settings);

/// Adapts geolocator live positions into ingestion [RawPoint] samples.
///
/// Recording points are buffered in-memory for the active session.
class LiveStreamAdapter {
  LiveStreamAdapter({PositionStreamFactory? positionStreamFactory})
      : _positionStreamFactory =
            positionStreamFactory ??
                ((settings) => Geolocator.getPositionStream(locationSettings: settings));

  final PositionStreamFactory _positionStreamFactory;
  final List<RawPoint> _buffer = <RawPoint>[];

  /// Read-only buffered points captured since last [clearBuffer].
  UnmodifiableListView<RawPoint> get bufferedPoints => UnmodifiableListView(_buffer);

  /// Clears the current recording-session buffer.
  void clearBuffer() => _buffer.clear();

  /// Opens the live GPS stream mapped to [RawPoint].
  ///
  /// Uses best accuracy and 2m distance filter for ski tracking.
  Stream<RawPoint> openLiveStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
    );

    return _positionStreamFactory(settings).map((position) {
      final point = RawPoint(
        lat: position.latitude,
        lon: position.longitude,
        ele: position.altitude,
        time: position.timestamp.toUtc(),
      );
      _buffer.add(point);
      return point;
    });
  }
}
