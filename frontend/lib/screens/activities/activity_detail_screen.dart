import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/config/app_config.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/engines/map/color_mode_styler.dart';
import 'package:snowtrak/engines/map/map_rendering_engine.dart';
import 'package:snowtrak/engines/map/ski_map_layer_loader.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/location.dart';
import 'package:snowtrak/models/processed_track.dart';
import 'package:snowtrak/models/segment.dart';
import 'package:snowtrak/models/track_point.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/services/map_config.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  Activity? _activity;
  bool _isLoading = true;

  ProcessedTrack? _track;
  List<Segment> _segments = const <Segment>[];

  Dio? _mapDio;
  MapRenderingEngine? _mapRenderingEngine;
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  MapVisualStyle _selectedMapStyle = MapVisualStyle.terrain;

  @override
  void initState() {
    super.initState();
    final mapBaseUrl = _normalizeMapBaseUrl(sl<AppConfig>().mapApiBaseUrl);
    _mapDio = Dio(BaseOptions(
      baseUrl: mapBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _mapRenderingEngine = MapRenderingEngine(
      skiTrailLoader:
          SkiMapLayerLoader(apiClient: DioSkiMapApiClient(_mapDio!)),
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
    if (!mounted) return;
    setState(() {
      _activity = activity;
      _isLoading = false;
    });
    if (activity != null) await _prepareRouteData(activity);
  }

  Future<void> _prepareRouteData(Activity activity) async {
    if (activity.locations.length < 2) {
      setState(() => _track = _toProcessedTrack(activity));
      return;
    }
    final track = _toProcessedTrack(activity);
    final segments = _localFallbackSegments(track.points);
    if (!mounted) return;
    setState(() {
      _track = track;
      _segments = segments;
    });
    await _initialiseMapIfReady();
  }

  ProcessedTrack _toProcessedTrack(Activity activity) {
    final sorted = List<Location>.from(activity.locations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final points = <TrackPoint>[];
    for (var i = 0; i < sorted.length; i++) {
      final cur = sorted[i];
      final prev = i > 0 ? sorted[i - 1] : null;
      points.add(TrackPoint(
        lat: cur.latitude,
        lon: cur.longitude,
        elevationM: cur.altitude ?? 0,
        timestamp: cur.timestamp.toUtc(),
        speedKmh: _speedKmh(cur, prev),
      ));
    }
    return ProcessedTrack(
      id: activity.id,
      points: points,
      recordedAt: points.first.timestamp,
      sourceType: SourceType.live,
    );
  }

  List<Segment> _localFallbackSegments(List<TrackPoint> points) {
    if (points.length < 2) return const <Segment>[];
    return <Segment>[
      Segment(
        type: SegmentType.descent,
        points: points,
        startIndex: 0,
        endIndex: points.length - 1,
        trailName: 'Detected run',
        difficulty: null,
      )
    ];
  }

  String _normalizeMapBaseUrl(String value) {
    var v = value.trim();
    while (v.endsWith('/')) v = v.substring(0, v.length - 1);
    if (v.toLowerCase().endsWith('/api')) v = v.substring(0, v.length - 4);
    return v;
  }

  double _speedKmh(Location cur, Location? prev) {
    final raw = cur.speed;
    if (prev == null) return raw == null ? 0 : raw * 3.6;
    final dt = cur.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0) return raw == null ? 0 : raw * 3.6;
    return (_haversineMeters(prev.latitude, prev.longitude, cur.latitude, cur.longitude) / dt) * 3.6;
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double v) => v * (pi / 180);

  Future<void> _initialiseMapIfReady() async {
    final c = _mapController;
    final t = _track;
    if (!_mapReady || c == null || t == null || _segments.isEmpty) return;
    await _mapRenderingEngine!.initialise(c,
        track: t, segments: _segments, initialColorMode: MapColorMode.segment);
    await _mapRenderingEngine!.fitToTrack(t);
  }

  Future<void> _zoomIn() async =>
      _mapController?.animateCamera(CameraUpdate.zoomIn());
  Future<void> _zoomOut() async =>
      _mapController?.animateCamera(CameraUpdate.zoomOut());

  void _setMapStyle(MapVisualStyle style) {
    if (_selectedMapStyle == style) return;
    setState(() {
      _selectedMapStyle = style;
      _mapReady = false;
      _mapController = null;
    });
  }

  Future<void> _confirmDelete(Activity activity) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: SnowtrakColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: SnowtrakColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: SnowtrakColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Delete Activity?',
                style: SnowtrakTypography.headlineMedium
                    .copyWith(color: SnowtrakColors.textPrimary)),
            const SizedBox(height: 8),
            Text('This cannot be undone.',
                style: SnowtrakTypography.bodyMedium
                    .copyWith(color: SnowtrakColors.textSecondary)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SnowtrakColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Delete',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: SnowtrakTypography.bodyMedium
                      .copyWith(color: SnowtrakColors.textSecondary)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      await provider.deleteActivity(activity.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SnowtrakColors.background,
        appBar: _buildAppBar(null),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SnowtrakColors.primary),
          ),
        ),
      );
    }

    if (_activity == null) {
      return Scaffold(
        backgroundColor: SnowtrakColors.background,
        appBar: _buildAppBar(null),
        body: Center(
          child: Text('Activity not found',
              style: SnowtrakTypography.bodyLarge
                  .copyWith(color: SnowtrakColors.textSecondary)),
        ),
      );
    }

    final activity = _activity!;
    final track = _track;
    final mapCenter = track != null && track.points.isNotEmpty
        ? LatLng(track.points.first.lat, track.points.first.lon)
        : (activity.locations.isNotEmpty
            ? LatLng(activity.locations.first.latitude,
                activity.locations.first.longitude)
            : const LatLng(46.8, 8.2));
    final hasRenderableTrack = track != null && track.points.length > 1;

    return Scaffold(
      backgroundColor: SnowtrakColors.background,
      appBar: _buildAppBar(activity),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Activity name + date ────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name?.isNotEmpty == true
                        ? activity.name!
                        : activity.type.displayName,
                    style: SnowtrakTypography.displaySmall.copyWith(
                      color: SnowtrakColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, y · h:mm a')
                        .format(activity.startTime),
                    style: SnowtrakTypography.bodySmall.copyWith(
                      color: SnowtrakColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Map ─────────────────────────────────────────────────
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  MapLibreMap(
                    key: ValueKey<String>(
                        'activity-${_selectedMapStyle.name}'),
                    styleString: MapConfig.styleForMode(_selectedMapStyle),
                    initialCameraPosition: CameraPosition(
                      target: mapCenter,
                      zoom: hasRenderableTrack ? 13 : 10,
                    ),
                    onMapCreated: (c) => _mapController = c,
                    onStyleLoadedCallback: () async {
                      _mapReady = true;
                      await _initialiseMapIfReady();
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _MapStyleToggle(
                      selectedStyle: _selectedMapStyle,
                      onSelected: _setMapStyle,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _MapZoomControls(
                        onZoomIn: _zoomIn, onZoomOut: _zoomOut),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats grid ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: SnowtrakColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                              child: _StatCell(
                                  label: 'Distance',
                                  value: activity.formattedDistance)),
                          VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: SnowtrakColors.surfaceVariant),
                          Expanded(
                              child: _StatCell(
                                  label: 'Avg Speed',
                                  value: activity.formattedSpeed)),
                        ],
                      ),
                    ),
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: SnowtrakColors.surfaceVariant),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                              child: _StatCell(
                                  label: 'Moving Time',
                                  value: activity.formattedDuration)),
                          VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: SnowtrakColors.surfaceVariant),
                          Expanded(
                              child: _StatCell(
                                  label: 'Elevation Gain',
                                  value:
                                      '+${activity.elevationGain.toStringAsFixed(0)} m')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Details ──────────────────────────────────────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: SnowtrakColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _DetailTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Start',
                        value: DateFormat('MMM d, y · h:mm a')
                            .format(activity.startTime)),
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: SnowtrakColors.surfaceVariant),
                    _DetailTile(
                        icon: Icons.flag_outlined,
                        label: 'End',
                        value: DateFormat('MMM d, y · h:mm a')
                            .format(activity.endTime)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(Activity? activity) {
    return AppBar(
      backgroundColor: SnowtrakColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: SnowtrakColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        activity?.type.displayName ?? '',
        style: SnowtrakTypography.headlineSmall.copyWith(
          color: SnowtrakColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (activity != null)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            color: SnowtrakColors.textPrimary,
            onPressed: () => _confirmDelete(activity),
          ),
      ],
    );
  }
}

// ─── Map controls ─────────────────────────────────────────────────────────────

class _MapStyleToggle extends StatelessWidget {
  const _MapStyleToggle(
      {required this.selectedStyle, required this.onSelected});
  final MapVisualStyle selectedStyle;
  final void Function(MapVisualStyle) onSelected;

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, MapVisualStyle style) {
      final active = selectedStyle == style;
      return Material(
        color: active ? SnowtrakColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelected(style),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label,
                style: TextStyle(
                  color: active ? Colors.white : SnowtrakColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn('2D', MapVisualStyle.clean2d),
          btn('Terrain', MapVisualStyle.terrain),
        ],
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls(
      {required this.onZoomIn, required this.onZoomOut});
  final Future<void> Function() onZoomIn;
  final Future<void> Function() onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add,
                color: SnowtrakColors.textPrimary, size: 20),
            onPressed: () => onZoomIn(),
          ),
          Container(
              width: 24,
              height: 1,
              color: SnowtrakColors.surfaceVariant),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove,
                color: SnowtrakColors.textPrimary, size: 20),
            onPressed: () => onZoomOut(),
          ),
        ],
      ),
    );
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: SnowtrakTypography.labelSmall.copyWith(
              color: SnowtrakColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: SnowtrakTypography.headlineMedium.copyWith(
              color: SnowtrakColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Details ──────────────────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  const _DetailTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SnowtrakColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(label,
                style: SnowtrakTypography.bodySmall
                    .copyWith(color: SnowtrakColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: SnowtrakTypography.bodyMedium
                    .copyWith(color: SnowtrakColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
