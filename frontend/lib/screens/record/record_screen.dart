import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/features/track_pipeline/application/track_pipeline_coordinator.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:syntrak/screens/record/activity_type_selector.dart';
import 'package:syntrak/screens/record/record_bottom_sheet.dart';
import 'package:syntrak/screens/record/record_error_view.dart';
import 'package:syntrak/screens/record/record_helpers.dart';
import 'package:syntrak/screens/record/record_map_view.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _mapController = Completer();
  bool _mapCompleterUsed = false;
  ActivityType? _selectedActivityType;
  bool _isRecording = false;
  bool _isPaused = false;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  final List<LatLng> _routePoints = [];
  CameraPosition? _initialCameraPosition;
  bool _hasError = false;
  String? _errorMessage;

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

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _locationService.checkPermissions();

      if (!hasPermission && mounted) {
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194),
            zoom: 15,
          );
          _hasError = false;
        });
        return;
      }

      final position = await _locationService.getCurrentPosition();

      if (position != null && mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          );
          _hasError = false;
        });
      } else if (mounted) {
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194),
            zoom: 15,
          );
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'The page is not ready!';
        });
      }
    }
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

    if (!mounted) return;
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

    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('GPS Required'),
            content: const Text(
              'We need your GPS service to record your activities trajectory. Please enable location access in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  if (context.mounted) Navigator.pop(context);
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
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _routePoints.clear();
    });

    _locationService.startTracking();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });

    _positionSubscription = _locationService.getPositionStream().listen(
      (position) {
        if (!_isPaused) {
          _locationService.addLocation(position);
          setState(() {
            _routePoints.add(LatLng(position.latitude, position.longitude));
          });

          _mapController.future.then((controller) {
            controller.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
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

    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);

    Activity activity;
    final appConfig = sl<AppConfig>();

    if (appConfig.useNivusPipeline) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.id;
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in required to save with server pipeline'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        final pipeline =
            await sl<TrackPipelineCoordinator>().processLiveLocations(
          userId: userId,
          locations: locations,
        );
        final stats = pipeline.stats;
        final distanceMeters = stats != null
            ? stats.totalDistanceKm * 1000
            : _locationService.calculateDistance();
        final elevationGain = stats?.totalVerticalDropM ??
            _locationService.calculateElevationGain();
        final durationSeconds =
            stats?.movingTime.inSeconds ?? _elapsedTime.inSeconds;
        final avgPace = stats != null && stats.avgSpeedKmh > 0
            ? 3600 / stats.avgSpeedKmh
            : 0.0;
        final maxPace = stats != null && stats.topSpeedKmh > 0
            ? 3600 / stats.topSpeedKmh
            : 0.0;

        activity = Activity(
          id: '',
          userId: userId,
          type: _selectedActivityType!,
          distance: distanceMeters,
          duration: durationSeconds,
          elevationGain: elevationGain,
          startTime: startTime,
          endTime: endTime,
          averagePace: avgPace,
          maxPace: maxPace,
          isPublic: true,
          createdAt: DateTime.now(),
          locations: locations,
          mapActivityId: pipeline.mapActivityId,
          processingStatus: ProcessingStatus.ready,
        );
      } catch (error, stackTrace) {
        AppLogger.instance.error(
          '[RecordScreen] Nivus pipeline save failed',
          error: error,
          stackTrace: stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pipeline processing failed. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      activity = Activity(
        id: '',
        userId: '',
        type: _selectedActivityType!,
        distance: _locationService.calculateDistance(),
        duration: _elapsedTime.inSeconds,
        elevationGain: _locationService.calculateElevationGain(),
        startTime: startTime,
        endTime: endTime,
        averagePace: 0,
        maxPace: 0,
        isPublic: true,
        createdAt: DateTime.now(),
        locations: locations,
      );
    }

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

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _startTime = null;
      _elapsedTime = Duration.zero;
      _routePoints.clear();
    });
    _locationService.clearLocations();
  }

  void _retryAfterError() {
    setState(() {
      _hasError = false;
      _initialCameraPosition = null;
      _errorMessage = null;
    });
    _initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return RecordErrorView(
        message: _errorMessage ?? 'The page is not ready!',
        onRetry: _retryAfterError,
      );
    }

    try {
      if (_initialCameraPosition == null) {
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
            RecordMapView(
              initialCameraPosition: _initialCameraPosition!,
              routePoints: _routePoints,
              onMapCreated: (controller) {
                if (!_mapCompleterUsed) {
                  _mapCompleterUsed = true;
                  _mapController.complete(controller);
                }
              },
            ),
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
                          borderRadius:
                              BorderRadius.circular(SyntrakRadius.round),
                        ),
                        child: Text(
                          formatRecordDuration(_elapsedTime),
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RecordBottomSheet(
                isRecording: _isRecording,
                selectedActivityType: _selectedActivityType,
                locationService: _locationService,
                routePoints: _routePoints,
                onSelectType: _selectActivityType,
                onStart: _startRecording,
                onStop: _stopRecording,
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('RecordScreen build: $e\n$stackTrace');
      return RecordErrorView(
        message: _errorMessage ?? 'The page is not ready!',
        onRetry: _retryAfterError,
      );
    }
  }
}
