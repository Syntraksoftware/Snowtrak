import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:syntrak/screens/record/activity_type_selector.dart';
import 'package:syntrak/screens/record/record_bottom_sheet.dart';
import 'package:syntrak/screens/record/record_error_view.dart';
import 'package:syntrak/screens/record/record_map_view.dart';
import 'package:syntrak/services/location_service.dart';

const _liveRouteSourceId = 'live-route';
const _liveRouteLayerId = 'live-route-layer';

// Only push a GeoJSON update when the user has moved this far (meters).
const _geoJsonUpdateThresholdM = 5.0;

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
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

    final shouldSave = await _showSaveDialog();

    if (shouldSave == true && mounted) {
      await _saveActivity();
    } else {
      _resetState();
    }
  }

  Future<bool?> _showSaveDialog() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Save Activity?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your route and stats will be saved to your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Discard',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveActivity() async {
    final locations = _locationService.locations;
    if (locations.isEmpty) return;

    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final activity = Activity(
      id: '',
      userId: auth.user?.id ?? '',
      type: _selectedActivityType!,
      distance: _locationService.calculateDistance(),
      duration: _elapsedNotifier.value.inSeconds,
      elevationGain: _locationService.calculateElevationGain(),
      startTime: locations.first.timestamp,
      endTime: locations.last.timestamp,
      averagePace: 0,
      maxPace: 0,
      isPublic: true,
      createdAt: DateTime.now(),
      locations: locations,
    );

    final saved = await activityProvider.createActivity(activity);

    if (saved != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activityId: saved.id),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save activity'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }

    _resetState();
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
  }

  @override
  Widget build(BuildContext context) {
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

      return const Scaffold(
        backgroundColor: Color(0xFF111827),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFFF5A1F)),
              ),
              SizedBox(height: 16),
              Text(
                'Acquiring GPS…',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SyntrakColors.darkBackground,
      body: Stack(
        children: [
          RecordMapView(
            initialCameraPosition: _initialCameraPosition!,
            myLocationTrackingMode: _trackingMode,
            onTrackingDismissed: () =>
                setState(() => _trackingMode = MyLocationTrackingMode.none),
            onMapCreated: (c) => _mapController = c,
            onStyleLoaded: _onMapStyleLoaded,
            onRecenter: _recentre,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RecordBottomSheet(
              isRecording: _isRecording,
              isPaused: _isPaused,
              selectedActivityType: _selectedActivityType,
              locationService: _locationService,
              routePoints: _routePoints,
              elapsedNotifier: _elapsedNotifier,
              onSelectType: _selectActivityType,
              onStart: _startRecording,
              onStop: _stopRecording,
              onPause: _pauseRecording,
              onResume: _resumeRecording,
            ),
          ),
        ],
      ),
    );
  }
}
