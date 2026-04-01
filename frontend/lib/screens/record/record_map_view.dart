import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecordMapView extends StatelessWidget {
  const RecordMapView({
    super.key,
    required this.initialCameraPosition,
    required this.routePoints,
    required this.onMapCreated,
  });

  final CameraPosition initialCameraPosition;
  final List<LatLng> routePoints;
  final void Function(GoogleMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: onMapCreated,
      polylines: routePoints.length > 1
          ? {
              Polyline(
                polylineId: const PolylineId('route'),
                points: routePoints,
                color: const Color(0xFFFF4500),
                width: 4,
              ),
            }
          : {},
    );
  }
}
