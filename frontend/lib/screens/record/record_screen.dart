import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/screens/record/activity_type_selector.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _mapController = Completer();
  ActivityType? _selectedActivityType;
  bool _isRecording = false;
  bool _isPaused = false;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  List<LatLng> _routePoints = [];
  CameraPosition? _initialCameraPosition;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Try to initialize location
    _initializeLocation().catchError((e) {
      print('🔍 [RecordScreen] Error in initState: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to initialize map. Please check your location permissions.";
        });
      }
    });
  }

  Future<void> _initializeLocation() async {
    print('🔍 [RecordScreen] Initializing location...');
    try {
      // Check if we have permission (don't request again, just check)
      print('🔍 [RecordScreen] Checking permissions...');
      final hasPermission = await _locationService.checkPermissions();
      print('🔍 [RecordScreen] Permission check result: $hasPermission');

      if (!hasPermission && mounted) {
        print(
            '🔍 [RecordScreen] Permission not granted, using default location');
        // If no permission, use a default location (San Francisco as fallback)
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194), // Default location
            zoom: 15,
          );
          _hasError = false;
        });
        return;
      }
      
      print('🔍 [RecordScreen] Permission granted, proceeding to get location');

      // Try to get current position with timeout
      print('🔍 [RecordScreen] Getting current position...');
      final position = await _locationService
          .getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      if (position != null && mounted) {
        print(
            '🔍 [RecordScreen] Position obtained: ${position.latitude}, ${position.longitude}');
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          );
          _hasError = false;
        });
      } else if (mounted) {
        print('🔍 [RecordScreen] Position is null, using default location');
        // Fallback to default location if position is null
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194),
            zoom: 15,
          );
          _hasError = false;
        });
      }
    } catch (e) {
      print('🔍 [RecordScreen] Error getting location: $e');
      // If anything fails, show error screen
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "The page is not ready!";
        });
      }
    }
    print('🔍 [RecordScreen] Location initialization complete');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  Future<void> _selectActivityType() async {
    final type = await Navigator.push<ActivityType>(
      context,
      MaterialPageRoute(builder: (_) => const ActivityTypeSelector()),
    );

    if (type != null) {
      setState(() {
        _selectedActivityType = type;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_selectedActivityType == null) {
      await _selectActivityType();
      if (_selectedActivityType == null) return;
    }

    // Check if we have permission
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        // Show dialog explaining why we need GPS
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('GPS Required'),
            content: const Text(
              'We need your GPS service to record your activities trajectory. Please enable location access in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.pop(context, false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4500),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldRequest == true && mounted) {
          // Try to request permission again
          final granted = await _locationService.requestPermissions();
          if (!granted) {
            return;
          }
        } else {
          return;
        }
      } else {
        return;
      }
    }

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _routePoints.clear();
    });

    _locationService.startTracking();

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });

    // Start location tracking
    _positionSubscription = _locationService.getPositionStream().listen(
      (position) {
        if (!_isPaused) {
          _locationService.addLocation(position);
          setState(() {
            _routePoints.add(LatLng(position.latitude, position.longitude));
          });

          // Update map camera
          _mapController.future.then((controller) {
            controller.animateCamera(
              CameraUpdate.newLatLng(
                  LatLng(position.latitude, position.longitude)),
            );
          });
        }
      },
    );
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = true;
    });
    _positionSubscription?.pause();
  }

  void _resumeRecording() {
    setState(() {
      _isPaused = false;
      _startTime = DateTime.now().subtract(_elapsedTime);
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
        _elapsedTime = Duration.zero;
      });
      return;
    }

    // Show confirmation dialog
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Activity?'),
        content: const Text('Do you want to save this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      await _saveActivity();
    } else {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _startTime = null;
        _elapsedTime = Duration.zero;
        _routePoints.clear();
      });
      _locationService.clearLocations();
    }
  }

  Future<void> _saveActivity() async {
    final locations = _locationService.locations;
    if (locations.isEmpty) return;

    final startTime = locations.first.timestamp;
    final endTime = locations.last.timestamp;

    final activity = Activity(
      id: '',
      userId: '',
      type: _selectedActivityType!,
      distance: _locationService.calculateDistance(),
      duration: _elapsedTime.inSeconds,
      elevationGain: _locationService.calculateElevationGain(),
      startTime: startTime,
      endTime: endTime,
      averagePace: 0, // Will be calculated by backend
      maxPace: 0, // Will be calculated by backend
      isPublic: true,
      createdAt: DateTime.now(),
      locations: locations,
    );

    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);
    final savedActivity = await activityProvider.createActivity(activity);

    if (savedActivity != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activityId: savedActivity.id),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save activity'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Reset state
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _startTime = null;
      _elapsedTime = Duration.zero;
      _routePoints.clear();
    });
    _locationService.clearLocations();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen by default to prevent crashes
    if (_hasError) {
      return _buildErrorScreen();
    }

    // Wrap entire build in error handling to prevent crashes
    try {
      // If still loading location, show loading but with timeout fallback
      if (_initialCameraPosition == null) {
        // Set a default after a short delay if location doesn't load
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _initialCameraPosition == null) {
            try {
              setState(() {
                _initialCameraPosition = const CameraPosition(
                  target: LatLng(37.7749, -122.4194),
                  zoom: 15,
                );
              });
            } catch (e) {
              print('🔍 [RecordScreen] Error setting default location: $e');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = "The page is not ready!";
                });
              }
            }
          }
        });
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading map...'),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        body: Stack(
          children: [
            // Map with error handling
            _buildMapWidget(),

            // Top overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: SyntrakColors.textPrimary,
                      onPressed:
                          _isRecording ? null : () => Navigator.pop(context),
                    ),
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: SyntrakColors.textPrimary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(SyntrakRadius.round),
                        ),
                        child: Text(
                          _formatDuration(_elapsedTime),
                          style: SyntrakTypography.metricLarge.copyWith(
                            color: SyntrakColors.textOnPrimary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    if (_isRecording)
                      IconButton(
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: SyntrakColors.textPrimary,
                      ),
                      onPressed:
                          _isPaused ? _resumeRecording : _pauseRecording,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(SyntrakSpacing.lg),
                decoration: BoxDecoration(
                  color: SyntrakColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(SyntrakRadius.xl),
                    topRight: Radius.circular(SyntrakRadius.xl),
                  ),
                  boxShadow: SyntrakElevation.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isRecording)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedActivityType == null
                              ? _selectActivityType
                              : _startRecording,
                          icon: _selectedActivityType == null
                              ? const Icon(Icons.add)
                              : Icon(ActivityHelpers.getActivityIcon(_selectedActivityType!)),
                          label: Text(
                            _selectedActivityType == null
                                ? 'Select Activity Type'
                                : 'Start Recording',
                            style: SyntrakTypography.labelLarge,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Skiing-specific metrics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric(
                                'Vertical',
                                '${_locationService.calculateElevationGain().toStringAsFixed(0)} m',
                              ),
                              _buildMetric(
                                'Distance',
                                '${(_locationService.calculateDistance() / 1000).toStringAsFixed(2)} km',
                              ),
                              _buildMetric(
                                'Speed',
                                _calculateCurrentSpeed(),
                              ),
                            ],
                          ),
                          const SizedBox(height: SyntrakSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _stopRecording,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SyntrakColors.error,
                                foregroundColor: SyntrakColors.textOnPrimary,
                              ),
                              child: Text(
                                'Stop Recording',
                                style: SyntrakTypography.labelLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('🔍 [RecordScreen] Error in build: $e');
      print('🔍 [RecordScreen] Stack trace: $stackTrace');
      // Show "page not ready" message instead of crashing
      return _buildErrorScreen();
    }
  }

  String _calculateCurrentSpeed() {
    if (_routePoints.length < 2) return '-- km/h';
    // Calculate speed from last two points
    final lastPoint = _routePoints.last;
    final secondLastPoint = _routePoints[_routePoints.length - 2];
    final distance = Geolocator.distanceBetween(
      secondLastPoint.latitude,
      secondLastPoint.longitude,
      lastPoint.latitude,
      lastPoint.longitude,
    );
    // Assuming 1 second between points
    final speedMs = distance / 1.0;
    final speedKmh = speedMs * 3.6;
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SyntrakTypography.metricMedium.copyWith(
              color: SyntrakColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SyntrakSpacing.xs),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        initialCameraPosition: _initialCameraPosition!,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _mapController.complete(controller);
        },
        polylines: _routePoints.length > 1
            ? {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _routePoints,
                  color: const Color(0xFFFF4500),
                  width: 4,
                ),
              }
            : {},
      );
    } catch (e, stackTrace) {
      print('🔍 [RecordScreen] Error building map: $e');
      print('🔍 [RecordScreen] Stack trace: $stackTrace');
      // Fallback: Show a placeholder instead of crashing
      return _buildErrorScreen();
    }
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Activity'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage ?? 'The page is not ready!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Map functionality is coming soon. You can still record activities without the map.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Retry by resetting state
                  setState(() {
                    _hasError = false;
                    _initialCameraPosition = null;
                    _errorMessage = null;
                  });
                  _initializeLocation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4500),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
