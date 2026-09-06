import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/services/map_config.dart';

class RecordMapView extends StatefulWidget {
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
  State<RecordMapView> createState() => _RecordMapViewState();
}

class _RecordMapViewState extends State<RecordMapView> {
  bool _styleLoaded = false;
  bool _timedOut = false;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    // ponytail: 10s covers slow connections; shows actionable error instead of silent blank
    _loadTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_styleLoaded) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _onStyleLoaded() {
    _loadTimer?.cancel();
    setState(() => _styleLoaded = true);
    widget.onStyleLoaded?.call();
  }

  void _retry() {
    setState(() {
      _styleLoaded = false;
      _timedOut = false;
    });
    _loadTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_styleLoaded) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          // ponytail: terrain locked during recording
          styleString: MapConfig.styleForMode(MapVisualStyle.terrain),
          initialCameraPosition: widget.initialCameraPosition,
          myLocationEnabled: true,
          myLocationTrackingMode: widget.myLocationTrackingMode,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onCameraTrackingDismissed: widget.onTrackingDismissed,
          onMapCreated: widget.onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
        ),
        if (_timedOut)
          Positioned.fill(
            child: _MapErrorOverlay(
              message: MapConfig.hasMapTilerApiKey
                  ? 'Map failed to load — check your network connection.'
                  : 'Map tiles not configured.\nRun with MAPTILER_API_KEY set.',
              onRetry: _retry,
            ),
          ),
      ],
    );
  }
}

class _MapErrorOverlay extends StatelessWidget {
  const _MapErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SnowtrakColors.darkBackground.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined,
                  color: context.colors.textOnPrimary.withValues(alpha: 0.54),
                  size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                style: SnowtrakTypography.bodyMedium
                    .copyWith(color: context.colors.textOnPrimary.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
