import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/engines/ingestion/gps_ingestion_engine.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';
import 'package:syntrak/engines/map/color_mode_styler.dart';
import 'package:syntrak/engines/map/map_rendering_engine.dart';
import 'package:syntrak/engines/map/ski_map_layer_loader.dart';
import 'package:syntrak/engines/segmentation/segment_detection_engine.dart';
import 'package:syntrak/engines/segmentation/trail_matcher.dart';
import 'package:syntrak/engines/stats/stats_engine.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/activity_stats.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/models/run_summary.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/services/map_config.dart';
import 'package:intl/intl.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {

  Activity? _activity;
  bool _isLoading = true;
  bool _isPreparingRoute = false;

  ProcessedTrack? _track;
  List<Segment> _segments = const <Segment>[];
  List<Segment> _descentSegments = const <Segment>[];
  List<RunSummary> _runSummaries = const <RunSummary>[];
  ActivityStats? _activityStats;
  String? _routeError;

  final StatsEngine _statsEngine = const StatsEngine();
  Dio? _mapDio;
  GpsIngestionEngine? _gpsIngestionEngine;
  SegmentDetectionEngine? _segmentDetectionEngine;
  MapRenderingEngine? _mapRenderingEngine;
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  bool _mapFeaturesEnabled = true;
  int? _selectedRunIndex;
  MapColorMode _selectedColorMode = MapColorMode.segment;
  MapVisualStyle _selectedMapStyle = MapVisualStyle.terrain;

  @override
  void initState() {
    super.initState();
    final appConfig = sl<AppConfig>();
    _mapFeaturesEnabled = appConfig.enableMapFeatures;
    if (!_mapFeaturesEnabled) {
      _loadActivity();
      return;
    }
    final mapBaseUrl = appConfig.mapApiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _mapDio = Dio(
      BaseOptions(
        baseUrl: mapBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _segmentDetectionEngine = SegmentDetectionEngine(
      trailMatcher: TrailMatcher(
        apiClient: DioTrailMatchApiClient(_mapDio!),
      ),
    );

    _gpsIngestionEngine = GpsIngestionEngine(
      elevationCorrector: ElevationCorrector(
        apiClient: DioApiClient(_mapDio!),
      ),
    );

    _mapRenderingEngine = MapRenderingEngine(
      skiTrailLoader: SkiMapLayerLoader(
        apiClient: DioSkiMapApiClient(_mapDio!),
      ),
    );

    _loadActivity();
  }

  @override
  void dispose() {
    _mapDio?.close(force: true);
    super.dispose();
  }

  Future<void> _loadActivity() async {
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    final activity = await provider.getActivity(widget.activityId);

    if (!mounted) {
      return;
    }

    setState(() {
      _activity = activity;
      _isLoading = false;
    });

    if (activity != null) {
      await _prepareRouteData(activity);
    }
  }

  Future<void> _prepareRouteData(Activity activity) async {
    if (activity.locations.length < 2) {
      final track = _toProcessedTrack(activity);
      setState(() {
        _track = track;
      });
      return;
    }

    setState(() {
      _isPreparingRoute = true;
      _routeError = null;
    });

    try {
      final track = _toProcessedTrack(activity);
      await _applyTrack(track);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routeError = 'Unable to build route analytics from this activity.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingRoute = false;
        });
      }
    }
  }

  Future<void> _uploadGpx() async {
    if (!_mapFeaturesEnabled) {
      setState(() {
        _routeError = 'Map features are disabled in staging for this beta build.';
      });
      return;
    }

    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['gpx'],
      allowMultiple: false,
    );

    if (pick == null || pick.files.isEmpty) {
      return;
    }

    final selected = pick.files.first;
    final path = selected.path;
    if (path == null || path.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routeError = 'Selected GPX file is not accessible from this platform.';
      });
      return;
    }

    setState(() {
      _isPreparingRoute = true;
      _routeError = null;
    });

    try {
      final gpsIngestionEngine = _gpsIngestionEngine;
      if (gpsIngestionEngine == null) {
        setState(() {
          _routeError = 'Map features are not available in this lane.';
        });
        return;
      }

      final track = await gpsIngestionEngine.processGpxFile(File(path));
      await _applyTrack(track);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded GPX route: ${selected.name}')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routeError = 'Failed to import GPX route. Please try another file.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingRoute = false;
        });
      }
    }
  }

  Future<void> _applyTrack(ProcessedTrack track) async {
    setState(() {
      _track = track;
    });

    if (!_mapFeaturesEnabled) {
      if (!mounted) {
        return;
      }

      setState(() {
        _segments = const <Segment>[];
        _descentSegments = const <Segment>[];
        _runSummaries = const <RunSummary>[];
        _activityStats = null;
        _selectedRunIndex = null;
      });
      return;
    }

    List<Segment> segments;
    try {
      segments = await _segmentDetectionEngine!.detect(track);
    } catch (_) {
      segments = _localFallbackSegments(track.points);
      if (segments.isNotEmpty && mounted) {
        setState(() {
          _routeError = 'Trail matching is unavailable right now. Showing local route only.';
        });
      }
    }

    if (segments.isEmpty && track.points.length > 1) {
      segments = _localFallbackSegments(track.points);
    }

    final stats = _statsEngine.compute(segments);
    final runSummaries = _statsEngine.buildRunSummaries(segments);
    final descentSegments =
        segments.where((s) => s.type == SegmentType.descent).toList(growable: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _segments = segments;
      _descentSegments = descentSegments;
      _runSummaries = runSummaries;
      _activityStats = stats;
      _selectedRunIndex = null;
    });

    await _initialiseMapIfReady();
  }

  ProcessedTrack _toProcessedTrack(Activity activity) {
    final sorted = List<Location>.from(activity.locations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final points = <TrackPoint>[];
    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final previous = i > 0 ? sorted[i - 1] : null;
      final computedSpeed = _speedKmh(current, previous);

      points.add(
        TrackPoint(
          lat: current.latitude,
          lon: current.longitude,
          elevationM: current.altitude ?? 0,
          timestamp: current.timestamp.toUtc(),
          speedKmh: computedSpeed,
        ),
      );
    }

    return ProcessedTrack(
      id: activity.id,
      points: points,
      recordedAt: points.first.timestamp,
      sourceType: SourceType.live,
    );
  }

  Segment _fallbackSegment(List<TrackPoint> points) {
    return Segment(
      type: SegmentType.descent,
      points: points,
      startIndex: 0,
      endIndex: points.length - 1,
      trailName: 'Detected run',
      difficulty: null,
    );
  }

  List<Segment> _localFallbackSegments(List<TrackPoint> points) {
    if (points.length < 2) {
      return const <Segment>[];
    }
    return <Segment>[_fallbackSegment(points)];
  }

  double _speedKmh(Location current, Location? previous) {
    final rawSpeedMps = current.speed;
    if (previous == null) {
      return rawSpeedMps == null ? 0 : rawSpeedMps * 3.6;
    }

    final deltaSeconds = current.timestamp
        .difference(previous.timestamp)
        .inMilliseconds /
        1000.0;

    if (deltaSeconds <= 0) {
      return rawSpeedMps == null ? 0 : rawSpeedMps * 3.6;
    }

    final distanceMeters = _haversineMeters(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    return (distanceMeters / deltaSeconds) * 3.6;
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _degToRad(double value) => value * (pi / 180);

  Future<void> _initialiseMapIfReady() async {
    if (!_mapFeaturesEnabled) {
      return;
    }

    final controller = _mapController;
    final track = _track;
    if (!_mapReady || controller == null || track == null || _segments.isEmpty) {
      return;
    }

    await _mapRenderingEngine!.initialise(
      controller,
      track: track,
      segments: _segments,
      initialColorMode: _selectedColorMode,
    );
    await _mapRenderingEngine!.fitToTrack(track);
  }

  Future<void> _onRunTap(int index) async {
    if (index < 0 || index >= _descentSegments.length) {
      return;
    }

    setState(() {
      _selectedRunIndex = index;
    });

    if (!_mapFeaturesEnabled) {
      return;
    }

    final segment = _descentSegments[index];
    await _mapRenderingEngine!.highlightSegment(segment);
    await _mapRenderingEngine!.zoomToSegment(segment);
  }

  Future<void> _onColorModeSelected(MapColorMode mode) async {
    if (_selectedColorMode == mode) {
      return;
    }

    setState(() {
      _selectedColorMode = mode;
    });

    if (!_mapFeaturesEnabled) {
      return;
    }

    unawaited(_mapRenderingEngine!.setColorMode(mode));
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

  void _setMapStyle(MapVisualStyle style) {
    if (_selectedMapStyle == style) {
      return;
    }

    setState(() {
      _selectedMapStyle = style;
      _mapReady = false;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity Details')),
        body: const Center(child: Text('Activity not found')),
      );
    }

    final activity = _activity!;
    final track = _track;
    final mapCenter = track != null && track.points.isNotEmpty
      ? LatLng(track.points.first.lat, track.points.first.lon)
      : (activity.locations.isNotEmpty
        ? LatLng(activity.locations.first.latitude, activity.locations.first.longitude)
        : const LatLng(46.8, 8.2));
    final hasRenderableTrack = track != null && track.points.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.type.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload GPX',
            onPressed: _isPreparingRoute || !_mapFeaturesEnabled ? null : _uploadGpx,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, activity),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  if (_mapFeaturesEnabled)
                    MapLibreMap(
                      key: ValueKey<String>('activity-${_selectedMapStyle.name}'),
                      styleString: MapConfig.styleForMode(_selectedMapStyle),
                      initialCameraPosition: CameraPosition(
                        target: mapCenter,
                        zoom: hasRenderableTrack ? 13 : 10,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      onStyleLoadedCallback: () async {
                        _mapReady = true;
                        await _initialiseMapIfReady();
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Map features disabled in staging',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'This lane keeps the beta focused on thread and activity flows while avoiding the unstable map backend.',
                          ),
                        ],
                      ),
                    ),
                  if (_mapFeaturesEnabled)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _MapStyleToggle(
                        selectedStyle: _selectedMapStyle,
                        onSelected: _setMapStyle,
                      ),
                    ),
                  if (_mapFeaturesEnabled)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _MapZoomControls(
                        onZoomIn: _zoomIn,
                        onZoomOut: _zoomOut,
                      ),
                    ),
                ],
              ),
            ),

            if (!_mapFeaturesEnabled)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Map is disabled in this lane. Thread, activity, and notification features remain available.',
                ),
              ),

            if (_mapFeaturesEnabled && !hasRenderableTrack && !_isPreparingRoute)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Map is available. Start recording or upload a GPX route to render your track.',
                ),
              ),

            if (_isPreparingRoute)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),

            if (_routeError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  _routeError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            if (hasRenderableTrack)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _ColorModeBar(
                  selected: _selectedColorMode,
                  onSelected: _onColorModeSelected,
                ),
              ),

            // Metrics
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metrics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Distance',
                          value: _activityStats == null
                              ? activity.formattedDistance
                              : '${_activityStats!.totalDistanceKm.toStringAsFixed(2)} km',
                          icon: Icons.straighten,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Duration',
                          value: _activityStats == null
                              ? activity.formattedDuration
                              : _formatDuration(_activityStats!.movingTime),
                          icon: Icons.timer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Pace',
                          value: _activityStats == null
                              ? activity.formattedPace
                              : '${_activityStats!.avgSpeedKmh.toStringAsFixed(1)} km/h',
                          icon: Icons.speed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Elevation',
                          value: _activityStats == null
                              ? '${activity.elevationGain.toStringAsFixed(0)} m'
                              : '${_activityStats!.totalVerticalDropM.toStringAsFixed(0)} m',
                          icon: Icons.terrain,
                        ),
                      ),
                    ],
                  ),
                  if (_runSummaries.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Runs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._runSummaries.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RunCard(
                          summary: entry.value,
                          selected: _selectedRunIndex == entry.key,
                          onTap: () => _onRunTap(entry.key),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Start Time',
                    value: DateFormat('MMM d, y • h:mm a').format(activity.startTime),
                  ),
                  _DetailRow(
                    label: 'End Time',
                    value: DateFormat('MMM d, y • h:mm a').format(activity.endTime),
                  ),
                  if (activity.name != null && activity.name!.isNotEmpty)
                    _DetailRow(
                      label: 'Name',
                      value: activity.name!,
                    ),
                  if (activity.description != null && activity.description!.isNotEmpty)
                    _DetailRow(
                      label: 'Description',
                      value: activity.description!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Future<void> _showDeleteDialog(BuildContext context, Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      await provider.deleteActivity(activity.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _MapStyleToggle extends StatelessWidget {
  const _MapStyleToggle({
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
          _MapStyleButton(
            label: '2D',
            selected: selectedStyle == MapVisualStyle.clean2d,
            onTap: () => onSelected(MapVisualStyle.clean2d),
          ),
          _MapStyleButton(
            label: 'Terrain',
            selected: selectedStyle == MapVisualStyle.terrain,
            onTap: () => onSelected(MapVisualStyle.terrain),
          ),
        ],
      ),
    );
  }
}

class _MapStyleButton extends StatelessWidget {
  const _MapStyleButton({
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

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
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

class _ColorModeBar extends StatelessWidget {
  const _ColorModeBar({
    required this.selected,
    required this.onSelected,
  });

  final MapColorMode selected;
  final Future<void> Function(MapColorMode mode) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ColorModeChip(
          mode: MapColorMode.segment,
          label: 'Segment',
          selected: selected == MapColorMode.segment,
          onSelected: onSelected,
        ),
        _ColorModeChip(
          mode: MapColorMode.speed,
          label: 'Speed',
          selected: selected == MapColorMode.speed,
          onSelected: onSelected,
        ),
        _ColorModeChip(
          mode: MapColorMode.elevation,
          label: 'Elevation',
          selected: selected == MapColorMode.elevation,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ColorModeChip extends StatelessWidget {
  const _ColorModeChip({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final MapColorMode mode;
  final String label;
  final bool selected;
  final Future<void> Function(MapColorMode mode) onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (value) {
        if (value) {
          unawaited(onSelected(mode));
        }
      },
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final RunSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xFFFFF7E1) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.runNumber,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(summary.trailName?.isNotEmpty == true ? summary.trailName! : 'Unmatched trail'),
              const SizedBox(height: 6),
              Text(
                '${summary.distanceKm.toStringAsFixed(2)} km • '
                '${summary.verticalDropM.toStringAsFixed(0)} m drop • '
                '${summary.avgSpeedKmh.toStringAsFixed(1)} km/h avg',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF4500)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

