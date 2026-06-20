import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:syntrak/services/map_config.dart';

class RecordMapView extends StatefulWidget {
  const RecordMapView({
    super.key,
    required this.initialCameraPosition,
    required this.onMapCreated,
    required this.myLocationTrackingMode,
    this.onTrackingDismissed,
    this.onStyleLoaded,
    this.onRecenter,
  });

  final CameraPosition initialCameraPosition;
  final void Function(MapLibreMapController) onMapCreated;
  final MyLocationTrackingMode myLocationTrackingMode;
  final VoidCallback? onTrackingDismissed;
  final VoidCallback? onStyleLoaded;
  final VoidCallback? onRecenter;

  @override
  State<RecordMapView> createState() => _RecordMapViewState();
}

class _RecordMapViewState extends State<RecordMapView> {
  MapLibreMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          // ponytail: terrain locked during recording — no style key needed
          styleString: MapConfig.styleForMode(MapVisualStyle.terrain),
          initialCameraPosition: widget.initialCameraPosition,
          myLocationEnabled: true,
          myLocationTrackingMode: widget.myLocationTrackingMode,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onCameraTrackingDismissed: () {
            widget.onTrackingDismissed?.call();
          },
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
          },
          onStyleLoadedCallback: () {
            widget.onStyleLoaded?.call();
          },
        ),
        Positioned(
          right: 16,
          bottom: 160,
          child: _RecentreButton(
            onTap: widget.onRecenter,
          ),
        ),
      ],
    );
  }
}

class _RecentreButton extends StatelessWidget {
  const _RecentreButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
