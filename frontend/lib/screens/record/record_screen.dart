import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/activities/activity_detail_screen.dart';
import 'package:snowtrak/screens/record/activity_type_selector.dart';
import 'package:snowtrak/screens/record/record_bottom_sheet.dart';
import 'package:snowtrak/screens/record/record_error_view.dart';
import 'package:snowtrak/screens/record/record_map_view.dart';
import 'package:snowtrak/services/location_service.dart';

const _liveRouteSourceId = 'live-route';
const _liveRouteLayerId = 'live-route-layer';

// Only push a GeoJSON update when the user has moved this far (meters).
const _geoJsonUpdateThresholdM = 5.0;

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final LocationService _locationService = LocationService();
  MapLibreMapController? _mapController;
  MyLocationTrackingMode _trackingMode = MyLocationTrackingMode.tracking;
  ActivityType? _selectedActivityType;
  bool _isRecording = false;
  bool _isPaused = false;
  DateTime? _startTime;
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  final List<LatLng> _routePoints = [];
  CameraPosition? _initialCameraPosition;
  bool _hasError = false;
  String? _errorMessage;

  // ValueNotifier so the timer ticks don't rebuild the map widget.
  final _elapsedNotifier = ValueNotifier<Duration>(Duration.zero);

  // Track last point where GeoJSON was pushed to avoid redundant redraws.
  LatLng? _lastGeoJsonUpdatePoint;

  // Processing overlay state — shown after save while pipeline runs.
  bool _isProcessing = false;
  double _rawDistance = 0;
  double _rawElevationGain = 0;
  Duration _rawDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeLocation().catchError((e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Failed to initialize map. Please check your location permissions.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _locationService.stopTracking();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _locationService.checkPermissions();
      final position = hasPermission
          ? await _locationService.getCurrentPosition()
          : null;

      if (!mounted) return;
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: position != null
              ? LatLng(position.latitude, position.longitude)
              : const LatLng(37.7749, -122.4194),
          zoom: 15,
        );
        _hasError = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize map.';
        });
      }
    }
  }

  Future<void> _onMapStyleLoaded() async {
    final controller = _mapController;
    if (controller == null) return;
    // Add the source/layer with empty data — path only appears after Start.
    await controller.addGeoJsonSource(
        _liveRouteSourceId, _emptyGeoJson());
    await controller.addLineLayer(
      _liveRouteSourceId,
      _liveRouteLayerId,
      const LineLayerProperties(
        lineColor: '#FF5A1F',
        lineWidth: 4.0,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );
  }

  Map<String, dynamic> _emptyGeoJson() =>
      {'type': 'FeatureCollection', 'features': []};

  Map<String, dynamic> _buildRouteGeoJson() {
    if (_routePoints.length < 2) return _emptyGeoJson();
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates':
                _routePoints.map((p) => [p.longitude, p.latitude]).toList(),
          },
          'properties': {},
        }
      ],
    };
  }

  Future<void> _selectActivityType() async {
    final type = await showActivityTypePicker(context);
    if (!mounted || type == null) return;
    setState(() => _selectedActivityType = type);
  }

  Future<void> _startRecording() async {
    if (_selectedActivityType == null) {
      await _selectActivityType();
      if (_selectedActivityType == null) return;
    }

    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        await showGpsDeniedSheet(context);
        await openAppSettings();
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _elapsedNotifier.value = Duration.zero;
      _routePoints.clear();
      _lastGeoJsonUpdatePoint = null;
      _trackingMode = MyLocationTrackingMode.tracking;
    });

    _locationService.startTracking();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        // Update notifier only — does NOT rebuild the map.
        _elapsedNotifier.value = DateTime.now().difference(_startTime!);
      }
    });

    _positionSubscription = _locationService.getPositionStream().listen(
      (position) {
        if (_isPaused) return;

        _locationService.addLocation(position);
        final newPoint = LatLng(position.latitude, position.longitude);
        _routePoints.add(newPoint);

        // Only push GeoJSON when moved enough to matter.
        final last = _lastGeoJsonUpdatePoint;
        final distMoved = last == null
            ? double.infinity
            : Geolocator.distanceBetween(
                last.latitude, last.longitude,
                newPoint.latitude, newPoint.longitude,
              );

        if (distMoved >= _geoJsonUpdateThresholdM) {
          _lastGeoJsonUpdatePoint = newPoint;
          _mapController?.setGeoJsonSource(
              _liveRouteSourceId, _buildRouteGeoJson());
        }
      },
    );
  }

  void _pauseRecording() {
    setState(() => _isPaused = true);
    _positionSubscription?.pause();
  }

  void _resumeRecording() {
    setState(() {
      _isPaused = false;
      _startTime = DateTime.now().subtract(_elapsedNotifier.value);
    });
    _positionSubscription?.resume();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _locationService.stopTracking();

    if (_locationService.locations.isEmpty) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _startTime = null;
        _elapsedNotifier.value = Duration.zero;
      });
      return;
    }

    // Compute once — shared by the dialog display and the save call.
    final rawDistance = _locationService.calculateDistance();
    final rawElevationGain = _locationService.calculateElevationGain();
    final rawDuration = _elapsedNotifier.value;

    final activityName =
        await _showSaveDialog(rawDistance, rawElevationGain, rawDuration);

    if (activityName != null && mounted) {
      await _saveActivity(activityName, rawDistance, rawElevationGain, rawDuration);
    } else {
      _resetState();
    }
  }

  Future<String?> _showSaveDialog(
      double distance, double elevation, Duration duration) {
    final hour = DateTime.now().hour;
    final timeOfDay =
        hour < 12 ? 'Morning' : (hour < 17 ? 'Afternoon' : 'Evening');
    final defaultName =
        '$timeOfDay ${_selectedActivityType?.displayName ?? 'Activity'}';
    final nameController = TextEditingController(text: defaultName);

    String fmtDist(double d) => d >= 1000
        ? '${(d / 1000).toStringAsFixed(2)} km'
        : '${d.toStringAsFixed(0)} m';
    String fmtDur(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Success badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: context.colors.primary, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                'Activity Complete',
                style: SnowtrakTypography.headlineMedium.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              if (_selectedActivityType != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _selectedActivityType!.displayName,
                    style: SnowtrakTypography.bodyMedium.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Editable activity name
              TextField(
                controller: nameController,
                style: SnowtrakTypography.bodyLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Activity name',
                  filled: true,
                  fillColor: context.colors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                          child: _StatItem(
                              value: fmtDist(distance), label: 'Distance')),
                      VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: context.colors.divider),
                      Expanded(
                          child: _StatItem(
                              value: fmtDur(duration), label: 'Time')),
                      VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: context.colors.divider),
                      Expanded(
                          child: _StatItem(
                              value: '+${elevation.toStringAsFixed(0)} m',
                              label: 'Elevation')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    Navigator.pop(context, name.isEmpty ? defaultName : name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save Activity',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'Discard',
                  style: SnowtrakTypography.bodyMedium.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveActivity(String name, double rawDistance,
      double rawElevationGain, Duration rawDuration) async {
    final locations = _locationService.locations;
    if (locations.isEmpty) return;

    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final activity = Activity(
      id: '',
      userId: auth.user?.id ?? '',
      name: name,
      type: _selectedActivityType!,
      distance: rawDistance,
      duration: rawDuration.inSeconds,
      elevationGain: rawElevationGain,
      startTime: locations.first.timestamp,
      endTime: locations.last.timestamp,
      averagePace: 0,
      maxPace: 0,
      isPublic: true,
      createdAt: DateTime.now(),
      locations: locations,
    );

    final saved = await activityProvider.createActivity(activity);

    if (saved == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save activity'),
            backgroundColor: context.colors.error,
          ),
        );
      }
      _resetState();
      return;
    }

    // If the backend already processed it inline, skip the wait.
    if (!saved.isPipelinePending) {
      _resetState();
      _navigateToDetail(saved.id);
      return;
    }

    // Show processing overlay while pipeline runs.
    _resetState();
    setState(() {
      _isProcessing = true;
      _rawDistance = rawDistance;
      _rawElevationGain = rawElevationGain;
      _rawDuration = rawDuration;
    });
    _pollPipelineStatus(saved.id);
  }

  Future<void> _pollPipelineStatus(String activityId) async {
    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (mounted && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      try {
        final activity = await activityProvider.getActivity(activityId);
        if (activity != null && !activity.isPipelinePending) {
          if (!mounted) return;
          // Refresh the full list so processed metrics (GPS distance, elevation)
          // replace the raw values and stats recompute with accurate data.
          unawaited(activityProvider.loadActivities(refresh: true, forceNetwork: true));
          setState(() => _isProcessing = false);
          _navigateToDetail(activityId);
          return;
        }
      } catch (_) {
        // swallow transient errors and keep polling until the deadline
      }
    }
    // Timed out: drop the overlay and navigate anyway (detail screen can
    // continue to reflect status) or surface a retry.
    if (mounted) {
      setState(() => _isProcessing = false);
      _navigateToDetail(activityId);
    }
  }

  void _navigateToDetail(String activityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activityId: activityId),
      ),
    );
  }

  void _resetState() {
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _startTime = null;
      _elapsedNotifier.value = Duration.zero;
      _routePoints.clear();
    });
    _locationService.clearLocations();
    // Clear the live route from the map.
    _mapController?.setGeoJsonSource(_liveRouteSourceId, _emptyGeoJson());
  }

  void _retryAfterError() {
    setState(() {
      _hasError = false;
      _initialCameraPosition = null;
      _errorMessage = null;
    });
    _initializeLocation();
  }

  void _recentre() {
    setState(() => _trackingMode = MyLocationTrackingMode.tracking);
    // Widget prop alone doesn't force a camera snap on an already-loaded map.
    // Animate explicitly to the last known position.
    final pos = _locationService.currentPosition;
    if (pos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(pos.latitude, pos.longitude), 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (_hasError) {
      return RecordErrorView(
        message: _errorMessage ?? 'The page is not ready!',
        onRetry: _retryAfterError,
      );
    }

    if (_initialCameraPosition == null) {
      // Fallback timeout after 3 s.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _initialCameraPosition == null) {
          setState(() {
            _initialCameraPosition = const CameraPosition(
              target: LatLng(37.7749, -122.4194),
              zoom: 15,
            );
          });
        }
      });

      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.colors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Acquiring GPS…',
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Approximate heights so layers don't overlap:
    //   controls bar  ≈ 120px
    //   stats card gap ≈ 12px
    //   stats card     ≈ 130px expanded / 56px collapsed
    const _controlsHeight = 120.0;
    const _statsCardBottom = _controlsHeight + 12.0;
    const _recentreBottom = _statsCardBottom + 140.0; // always above stats card

    return Scaffold(
      backgroundColor: SnowtrakColors.darkBackground,
      body: Stack(
        children: [
          // 1 — Full-screen map
          RecordMapView(
            initialCameraPosition: _initialCameraPosition!,
            myLocationTrackingMode: _trackingMode,
            onTrackingDismissed: () =>
                setState(() => _trackingMode = MyLocationTrackingMode.none),
            onMapCreated: (c) => _mapController = c,
            onStyleLoaded: _onMapStyleLoaded,
          ),

          // 2 — Re-centre button (right side, above stats card)
          Positioned(
            right: 16,
            bottom: _recentreBottom,
            child: _RecentreButton(onTap: _recentre),
          ),

          // 3 — Stats card (floating, collapsible)
          Positioned(
            left: 16,
            right: 16,
            bottom: _statsCardBottom,
            child: RecordStatsCard(
              isRecording: _isRecording,
              selectedActivityType: _selectedActivityType,
              locationService: _locationService,
              routePoints: _routePoints,
              elapsedNotifier: _elapsedNotifier,
              onSelectType: _selectActivityType,
            ),
          ),

          // 4 — Controls bar (pinned to very bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RecordControls(
              isRecording: _isRecording,
              isPaused: _isPaused,
              activityType: _selectedActivityType,
              onSelectType: _selectActivityType,
              onStart: _startRecording,
              onStop: _stopRecording,
              onPause: _pauseRecording,
              onResume: _resumeRecording,
            ),
          ),

          // 5 — Pipeline processing overlay (blocks all input until ready)
          if (_isProcessing)
            Positioned.fill(
              child: _ProcessingOverlay(
                distance: _rawDistance,
                elevationGain: _rawElevationGain,
                duration: _rawDuration,
                activityType: _selectedActivityType,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Processing overlay ───────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({
    required this.distance,
    required this.elevationGain,
    required this.duration,
    this.activityType,
  });

  final double distance;
  final double elevationGain;
  final Duration duration;
  final ActivityType? activityType;

  String get _formattedDistance => distance >= 1000
      ? '${(distance / 1000).toStringAsFixed(2)} km'
      : '${distance.toStringAsFixed(0)} m';

  String get _formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: context.colors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.colors.primary),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Saving Activity',
                  style: SnowtrakTypography.headlineMedium.copyWith(
                    color: context.colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  activityType != null
                      ? 'Matching trails for your ${activityType!.displayName.toLowerCase()}…'
                      : 'Matching trails and correcting elevation…',
                  style: SnowtrakTypography.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                            child: _StatItem(
                                label: 'Distance',
                                value: _formattedDistance)),
                        VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: context.colors.divider),
                        Expanded(
                            child: _StatItem(
                                label: 'Elevation',
                                value:
                                    '+${elevationGain.toStringAsFixed(0)} m')),
                        VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: context.colors.divider),
                        Expanded(
                            child: _StatItem(
                                label: 'Time', value: _formattedDuration)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: SnowtrakTypography.headlineSmall.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: SnowtrakTypography.labelSmall.copyWith(
            color: context.colors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}


// ─── Re-centre FAB ────────────────────────────────────────────────────────────

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
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.my_location,
            color: context.colors.primary, size: 20),
      ),
    );
  }
}
