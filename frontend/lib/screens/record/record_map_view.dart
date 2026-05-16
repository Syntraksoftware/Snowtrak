import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:syntrak/services/map_config.dart';

class RecordMapView extends StatefulWidget {
  const RecordMapView({
    super.key,
    required this.initialCameraPosition,
    required this.routePoints,
    required this.onMapCreated,
    required this.myLocationTrackingMode,
    this.onTrackingDismissed,
  });

  final CameraPosition initialCameraPosition;
  final List<LatLng> routePoints;
  final void Function(MapLibreMapController) onMapCreated;
  final MyLocationTrackingMode myLocationTrackingMode;
  final VoidCallback? onTrackingDismissed;

  @override
  State<RecordMapView> createState() => _RecordMapViewState();
}

class _RecordMapViewState extends State<RecordMapView> {
  MapLibreMapController? _mapController;
  MapVisualStyle _selectedStyle = MapVisualStyle.terrain;

  Future<void> _zoomIn() async {
    if (_mapController == null) {
      return;
    }
    await _mapController!.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    if (_mapController == null) {
      return;
    }
    await _mapController!.animateCamera(CameraUpdate.zoomOut());
  }

  void _setStyle(MapVisualStyle style) {
    if (_selectedStyle == style) {
      return;
    }

    setState(() {
      _selectedStyle = style;
      _mapController = null;
    });

    final source = MapConfig.resolvedSourceLabel(style);
    final needsMapTiler = style == MapVisualStyle.terrain;
    final suffix = needsMapTiler && !MapConfig.hasMapTilerApiKey
        ? ' (MAPTILER_API_KEY not set)'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map style: $source$suffix'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          key: ValueKey<String>('record-${_selectedStyle.name}'),
          styleString: MapConfig.styleForMode(_selectedStyle),
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
        ),
        Positioned(
          top: 12,
          right: 10,
          child: _RecordStyleToggle(
            selectedStyle: _selectedStyle,
            onSelected: _setStyle,
          ),
        ),
        Positioned(
          right: 10,
          bottom: 12,
          child: _RecordZoomControls(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
          ),
        ),
      ],
    );
  }
}

class _RecordStyleToggle extends StatelessWidget {
  const _RecordStyleToggle({
    required this.selectedStyle,
    required this.onSelected,
  });

  final MapVisualStyle selectedStyle;
  final void Function(MapVisualStyle style) onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RecordStyleButton(
            label: '2D',
            selected: selectedStyle == MapVisualStyle.clean2d,
            onTap: () => onSelected(MapVisualStyle.clean2d),
          ),
          _RecordStyleButton(
            label: 'Terrain',
            selected: selectedStyle == MapVisualStyle.terrain,
            onTap: () => onSelected(MapVisualStyle.terrain),
          ),
        ],
      ),
    );
  }
}

class _RecordStyleButton extends StatelessWidget {
  const _RecordStyleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFF5A1F) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordZoomControls extends StatelessWidget {
  const _RecordZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final Future<void> Function() onZoomIn;
  final Future<void> Function() onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add),
            onPressed: () => onZoomIn(),
            tooltip: 'Zoom in',
          ),
          Container(
            width: 30,
            height: 1,
            color: Colors.black12,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove),
            onPressed: () => onZoomOut(),
            tooltip: 'Zoom out',
          ),
        ],
      ),
    );
  }
}
