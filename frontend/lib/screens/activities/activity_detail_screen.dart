import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/engines/map/color_mode_styler.dart';
import 'package:syntrak/engines/map/map_rendering_engine.dart';
import 'package:syntrak/engines/map/ski_map_layer_loader.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/services/map_config.dart';

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
  MapColorMode _selectedColorMode = MapColorMode.segment;
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
      final current = sorted[i];
      final previous = i > 0 ? sorted[i - 1] : null;
      points.add(TrackPoint(
        lat: current.latitude,
        lon: current.longitude,
        elevationM: current.altitude ?? 0,
        timestamp: current.timestamp.toUtc(),
        speedKmh: _speedKmh(current, previous),
      ));
    }
    return ProcessedTrack(
      id: activity.id,
      points: points,
      recordedAt: points.first.timestamp,
      sourceType: SourceType.live,
    );
  }

  Segment _fallbackSegment(List<TrackPoint> points) => Segment(
        type: SegmentType.descent,
        points: points,
        startIndex: 0,
        endIndex: points.length - 1,
        trailName: 'Detected run',
        difficulty: null,
      );

  List<Segment> _localFallbackSegments(List<TrackPoint> points) {
    if (points.length < 2) return const <Segment>[];
    return <Segment>[_fallbackSegment(points)];
  }

  String _normalizeMapBaseUrl(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.toLowerCase().endsWith('/api')) {
      return trimmed.substring(0, trimmed.length - 4);
    }
    return trimmed;
  }

  double _speedKmh(Location current, Location? previous) {
    final rawSpeedMps = current.speed;
    if (previous == null) return rawSpeedMps == null ? 0 : rawSpeedMps * 3.6;
    final deltaSeconds =
        current.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
    if (deltaSeconds <= 0) return rawSpeedMps == null ? 0 : rawSpeedMps * 3.6;
    final distanceMeters = _haversineMeters(
      previous.latitude, previous.longitude,
      current.latitude, current.longitude,
    );
    return (distanceMeters / deltaSeconds) * 3.6;
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    return earthRadiusM * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degToRad(double value) => value * (pi / 180);

  Future<void> _initialiseMapIfReady() async {
    final controller = _mapController;
    final track = _track;
    if (!_mapReady || controller == null || track == null || _segments.isEmpty) return;
    await _mapRenderingEngine!.initialise(
      controller,
      track: track,
      segments: _segments,
      initialColorMode: _selectedColorMode,
    );
    await _mapRenderingEngine!.fitToTrack(track);
  }

  Future<void> _onColorModeSelected(MapColorMode mode) async {
    if (_selectedColorMode == mode) return;
    setState(() => _selectedColorMode = mode);
    unawaited(_mapRenderingEngine!.setColorMode(mode));
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: SyntrakColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: SyntrakColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Delete Activity?',
                style: SyntrakTypography.headlineMedium
                    .copyWith(color: SyntrakColors.textPrimary)),
            const SizedBox(height: 8),
            Text('This cannot be undone.',
                style: SyntrakTypography.bodyMedium
                    .copyWith(color: SyntrakColors.textSecondary)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SyntrakColors.error,
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
                  style: SyntrakTypography.bodyMedium
                      .copyWith(color: SyntrakColors.textTertiary)),
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
        backgroundColor: SyntrakColors.background,
        appBar: AppBar(backgroundColor: SyntrakColors.surface),
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
          ),
        ),
      );
    }

    if (_activity == null) {
      return Scaffold(
        backgroundColor: SyntrakColors.background,
        appBar: AppBar(
          backgroundColor: SyntrakColors.surface,
          title: const Text('Activity'),
        ),
        body: Center(
          child: Text('Activity not found',
              style: SyntrakTypography.bodyLarge
                  .copyWith(color: SyntrakColors.textSecondary)),
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

    final title = activity.name?.isNotEmpty == true
        ? activity.name!
        : activity.type.displayName;
    final dateStr =
        DateFormat('MMM d, y · h:mm a').format(activity.startTime);

    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        backgroundColor: SyntrakColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: SyntrakColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: SyntrakTypography.headlineSmall
                    .copyWith(color: SyntrakColors.textPrimary)),
            Text(dateStr,
                style: SyntrakTypography.bodySmall
                    .copyWith(color: SyntrakColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            color: SyntrakColors.textTertiary,
            onPressed: () => _confirmDelete(activity),
            tooltip: 'Delete activity',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Map ──────────────────────────────────────────────────
            SizedBox(
              height: 260,
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

            // ── Color mode chips ─────────────────────────────────────
            if (hasRenderableTrack)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _ColorModeBar(
                  selected: _selectedColorMode,
                  onSelected: _onColorModeSelected,
                ),
              )
            else
              const SizedBox(height: 16),

            // ── Stats card ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: SyntrakColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SyntrakColors.divider),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                          child: _StatCell(
                              value: activity.formattedDistance,
                              label: 'Distance')),
                      VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: SyntrakColors.divider),
                      Expanded(
                          child: _StatCell(
                              value: activity.formattedDuration,
                              label: 'Time')),
                      VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: SyntrakColors.divider),
                      Expanded(
                          child: _StatCell(
                              value:
                                  '+${activity.elevationGain.toStringAsFixed(0)} m',
                              label: 'Elevation')),
                      VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: SyntrakColors.divider),
                      Expanded(
                          child: _StatCell(
                              value: activity.formattedSpeed,
                              label: 'Avg Speed')),
                    ],
                  ),
                ),
              ),
            ),

            // ── Details ──────────────────────────────────────────────
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: SyntrakColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SyntrakColors.divider),
                ),
                child: Column(
                  children: [
                    _DetailTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Start',
                        value: DateFormat('MMM d, y · h:mm a')
                            .format(activity.startTime)),
                    Divider(height: 1, color: SyntrakColors.divider),
                    _DetailTile(
                        icon: Icons.flag_outlined,
                        label: 'End',
                        value: DateFormat('MMM d, y · h:mm a')
                            .format(activity.endTime)),
                    if (activity.name?.isNotEmpty == true) ...[
                      Divider(height: 1, color: SyntrakColors.divider),
                      _DetailTile(
                          icon: Icons.label_outline_rounded,
                          label: 'Name',
                          value: activity.name!),
                    ],
                    if (activity.description?.isNotEmpty == true) ...[
                      Divider(height: 1, color: SyntrakColors.divider),
                      _DetailTile(
                          icon: Icons.notes_rounded,
                          label: 'Note',
                          value: activity.description!),
                    ],
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
}

// ─── Map controls ─────────────────────────────────────────────────────────────

class _MapStyleToggle extends StatelessWidget {
  const _MapStyleToggle(
      {required this.selectedStyle, required this.onSelected});

  final MapVisualStyle selectedStyle;
  final void Function(MapVisualStyle) onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StyleBtn(
              label: '2D',
              selected: selectedStyle == MapVisualStyle.clean2d,
              onTap: () => onSelected(MapVisualStyle.clean2d)),
          _StyleBtn(
              label: 'Terrain',
              selected: selectedStyle == MapVisualStyle.terrain,
              onTap: () => onSelected(MapVisualStyle.terrain)),
        ],
      ),
    );
  }
}

class _StyleBtn extends StatelessWidget {
  const _StyleBtn(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? SyntrakColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : SyntrakColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, color: SyntrakColors.textPrimary, size: 20),
            onPressed: () => onZoomIn(),
          ),
          Container(width: 24, height: 1, color: SyntrakColors.divider),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove,
                color: SyntrakColors.textPrimary, size: 20),
            onPressed: () => onZoomOut(),
          ),
        ],
      ),
    );
  }
}

// ─── Color mode chips ─────────────────────────────────────────────────────────

class _ColorModeBar extends StatelessWidget {
  const _ColorModeBar({required this.selected, required this.onSelected});

  final MapColorMode selected;
  final Future<void> Function(MapColorMode) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ModeChip(
              mode: MapColorMode.segment,
              label: 'Segment',
              selected: selected == MapColorMode.segment,
              onTap: () => onSelected(MapColorMode.segment)),
          const SizedBox(width: 8),
          _ModeChip(
              mode: MapColorMode.speed,
              label: 'Speed',
              selected: selected == MapColorMode.speed,
              onTap: () => onSelected(MapColorMode.speed)),
          const SizedBox(width: 8),
          _ModeChip(
              mode: MapColorMode.elevation,
              label: 'Elevation',
              selected: selected == MapColorMode.elevation,
              onTap: () => onSelected(MapColorMode.elevation)),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip(
      {required this.mode,
      required this.label,
      required this.selected,
      required this.onTap});

  final MapColorMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? SyntrakColors.primary
              : SyntrakColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected
                  ? SyntrakColors.primary
                  : SyntrakColors.divider),
        ),
        child: Text(
          label,
          style: SyntrakTypography.labelMedium.copyWith(
            color: selected ? Colors.white : SyntrakColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: SyntrakTypography.headlineSmall.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textTertiary,
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
          Icon(icon, size: 18, color: SyntrakColors.textTertiary),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(label,
                style: SyntrakTypography.bodySmall
                    .copyWith(color: SyntrakColors.textTertiary)),
          ),
          Expanded(
            child: Text(
              value,
              style: SyntrakTypography.bodyMedium
                  .copyWith(color: SyntrakColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
