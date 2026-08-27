import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/activity_helpers.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/screens/activities/activity_detail_screen.dart';
import 'package:snowtrak/services/apis/map_activities_api.dart';
import 'package:snowtrak/services/location_service.dart';
import 'package:snowtrak/services/map_config.dart';
import 'package:snowtrak/ui/st/st.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

const _trailSourceId = 'ski-trails';
const _trailLayerId = 'ski-trails-layer';

class _MapsScreenState extends State<MapsScreen> {
  final LocationService _locationService = LocationService();
  MapLibreMapController? _mapController;
  CameraPosition? _initialCameraPosition;
  MapVisualStyle _selectedStyle = MapVisualStyle.terrain;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Activity> _activities = [];
  bool _trailsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadActivities();
  }

  Future<void> _initializeMap() async {
    try {
      // Check permissions
      final hasPermission = await _locationService.checkPermissions();

      if (!hasPermission) {
        // Use default location if no permission
        if (!mounted) return;
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194), // San Francisco
            zoom: 12,
          );
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await _locationService
          .getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      if (position != null) {
        if (!mounted) return;
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13,
          );
          _isLoading = false;
        });
      } else {
        // Fallback to default
        if (!mounted) return;
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194),
            zoom: 12,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MapsScreen] Error initializing map: $e');
      // The location lookup has a 10s timeout. Leaving the tab before it
      // fires disposes this state, and the catch below used to setState on a
      // dead widget -- an unhandled exception on every such exit.
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize map';
        _isLoading = false;
        _initialCameraPosition = const CameraPosition(
          target: LatLng(37.7749, -122.4194),
          zoom: 12,
        );
      });
    }
  }

  Future<void> _loadActivities() async {
    try {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      await provider.loadActivities();
      
      setState(() {
        _activities = provider.activities;
      });
    } catch (e) {
      debugPrint('[MapsScreen] Error loading activities: $e');
    }
  }

  Future<void> _onStyleLoaded() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.addGeoJsonSource(
      _trailSourceId,
      const {'type': 'FeatureCollection', 'features': []},
    );
    await controller.addLineLayer(
      _trailSourceId,
      _trailLayerId,
      const LineLayerProperties(
        lineColor: [
          'match', ['get', 'difficulty'],
          'easy',         '#4CAF50',
          'novice',       '#4CAF50',
          'intermediate', '#2196F3',
          'advanced',     '#212121',
          'expert',       '#212121',
          'freeride',     '#FF5A1F',
          '#9E9E9E', // fallback (null / unknown)
        ],
        lineWidth: 2.5,
        lineOpacity: 0.85,
      ),
    );
    _trailsLoaded = true;
    await _refreshTrails();
  }

  // ponytail: fires on every camera idle — add client-side bbox debounce if this gets chatty
  Future<void> _refreshTrails() async {
    final controller = _mapController;
    if (controller == null || !_trailsLoaded) return;
    final zoom = controller.cameraPosition?.zoom ?? 0;
    if (zoom < 11) return; // too zoomed out for trail detail
    try {
      final bounds = await controller.getVisibleRegion();
      if (!_isUsableBbox(bounds)) return;
      final geojson = await sl<MapActivitiesApi>().getResortTrails(bounds);
      await controller.setGeoJsonSource(_trailSourceId, geojson);
    } catch (e) {
      debugPrint('[MapsScreen] Failed to refresh trails: $e');
    }
  }

  /// The map reports a zero-area region before it has laid out, and a wrapped
  /// one when the view crosses the antimeridian. The backend rejects both with
  /// a 422, so there is nothing worth asking for.
  bool _isUsableBbox(LatLngBounds bounds) =>
      bounds.southwest.longitude < bounds.northeast.longitude &&
      bounds.southwest.latitude < bounds.northeast.latitude;

  void _showActivityDetails(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
  }

  Future<void> _centerOnMyLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    }
  }

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
      _trailsLoaded = false;
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
    if (_hasError && _initialCameraPosition == null) {
      return Scaffold(
        appBar: const StPageHeader(title: 'Map'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? 'Failed to load map',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _initializeMap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.textOnPrimary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading || _initialCameraPosition == null) {
      return Scaffold(
        appBar: const StPageHeader(title: 'Map'),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: StPageHeader(
        title: 'Map',
        actions: [
          StRoundButton(
            icon: StIcons.pin,
            tooltip: 'Center on my location',
            onTap: _centerOnMyLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            key: ValueKey<String>('maps-${_selectedStyle.name}'),
            styleString: MapConfig.styleForMode(_selectedStyle),
            initialCameraPosition: _initialCameraPosition!,
            myLocationEnabled: false,
            onMapCreated: (controller) => setState(() => _mapController = controller),
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraIdle: _refreshTrails,
          ),
          // Activity list overlay
          if (_activities.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                // ponytail: the strip is a fixed height because a horizontal
                // ListView needs a bounded one. 120 was 16px short of what
                // _ActivityCard actually draws, which overflowed on every
                // frame. If text scaling ever pushes past this, make the card
                // size the strip instead of hard-coding it.
                height: 148,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.textPrimary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${_activities.length} Activities',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return _ActivityCard(
                            activity: activity,
                            onTap: () => _showActivityDetails(activity),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 16,
            right: 12,
            child: _StyleToggle(
              selectedStyle: _selectedStyle,
              onSelected: _setStyle,
            ),
          ),

          Positioned(
            right: 12,
            bottom: _activities.isNotEmpty ? 140 : 24,
            child: _ZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),

          Positioned(
            left: 12,
            bottom: _activities.isNotEmpty ? 140 : 24,
            child: FloatingActionButton.small(
              heroTag: 'maps-center-location',
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.textOnPrimary,
              onPressed: _centerOnMyLocation,
              tooltip: 'Center on my location',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleToggle extends StatelessWidget {
  const _StyleToggle({
    required this.selectedStyle,
    required this.onSelected,
  });

  final MapVisualStyle selectedStyle;
  final void Function(MapVisualStyle style) onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StyleToggleButton(
            label: '2D',
            selected: selectedStyle == MapVisualStyle.clean2d,
            onTap: () => onSelected(MapVisualStyle.clean2d),
          ),
          _StyleToggleButton(
            label: 'Terrain',
            selected: selectedStyle == MapVisualStyle.terrain,
            onTap: () => onSelected(MapVisualStyle.terrain),
          ),
        ],
      ),
    );
  }
}

class _StyleToggleButton extends StatelessWidget {
  const _StyleToggleButton({
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
      color: selected ? context.colors.primary : context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? context.colors.textOnPrimary : context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final Future<void> Function() onZoomIn;
  final Future<void> Function() onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withValues(alpha: 0.12),
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
            color: context.colors.scrim.withValues(alpha: 0.12),
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

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    ActivityHelpers.getActivityIcon(activity.type),
                    color: ActivityHelpers.getActivityColor(activity.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.type.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.formattedDistance,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity.formattedDuration,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
