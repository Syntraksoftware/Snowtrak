import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:syntrak/services/map_config.dart';

class RecordMapView extends StatelessWidget {
  const RecordMapView({
    super.key,
    required this.initialCameraPosition,
    required this.onMapCreated,
    required this.myLocationTrackingMode,
    this.onTrackingDismissed,
    this.onStyleLoaded,
  });

  final CameraPosition initialCameraPosition;
  final void Function(MapLibreMapController) onMapCreated;
  final MyLocationTrackingMode myLocationTrackingMode;
  final VoidCallback? onTrackingDismissed;
  final VoidCallback? onStyleLoaded;

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      // ponytail: terrain locked during recording
      styleString: MapConfig.styleForMode(MapVisualStyle.terrain),
      initialCameraPosition: initialCameraPosition,
      myLocationEnabled: true,
      myLocationTrackingMode: myLocationTrackingMode,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onCameraTrackingDismissed: onTrackingDismissed,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoaded,
    );
  }
}
