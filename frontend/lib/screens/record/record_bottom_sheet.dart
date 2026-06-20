import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/record/record_helpers.dart';
import 'package:syntrak/services/location_service.dart';

// The Strava-style bottom panel: activity chip | stats row | 3-button row.
// Same widget handles both idle (pre-recording) and active states.
class RecordBottomSheet extends StatelessWidget {
  const RecordBottomSheet({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.selectedActivityType,
    required this.locationService,
    required this.routePoints,
    required this.elapsedNotifier,
    required this.onSelectType,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  final bool isRecording;
  final bool isPaused;
  final ActivityType? selectedActivityType;
  final LocationService locationService;
  final List<LatLng> routePoints;
  final ValueNotifier<Duration> elapsedNotifier;
  final VoidCallback onSelectType;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  static const _bg = Color(0xFF0F0F0F);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 24, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Activity type label row
          _ActivityRow(
            type: selectedActivityType,
            isRecording: isRecording,
            onTap: isRecording ? null : onSelectType,
          ),

          const SizedBox(height: 14),

          // Stats card — visually separated from activity chip and buttons
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: ValueListenableBuilder<Duration>(
              valueListenable: elapsedNotifier,
              builder: (_, elapsed, __) => _StatsRow(
                elapsed: elapsed,
                locationService: locationService,
                routePoints: routePoints,
                isRecording: isRecording,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Control buttons
          _ButtonRow(
            isRecording: isRecording,
            isPaused: isPaused,
            activityType: selectedActivityType,
            onSelectType: onSelectType,
            onStart: onStart,
            onStop: onStop,
            onPause: onPause,
            onResume: onResume,
          ),
        ],
      ),
    );
  }
}

// ─── Activity label row ───────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.type,
    required this.isRecording,
    this.onTap,
  });

  final ActivityType? type;
  final bool isRecording;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = type?.displayName ?? 'Select Activity';
    final icon = type != null ? ActivityHelpers.getActivityIcon(type!) : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: type != null ? Colors.white : const Color(0xFFFF5A1F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          if (!isRecording) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.elapsed,
    required this.locationService,
    required this.routePoints,
    required this.isRecording,
  });

  final Duration elapsed;
  final LocationService locationService;
  final List<LatLng> routePoints;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final timeStr = formatRecordDuration(elapsed);
    final distKm =
        (locationService.calculateDistance() / 1000).toStringAsFixed(2);
    final speed =
        isRecording ? formatSpeedFromRouteTail(routePoints) : '--';

    return Row(
      children: [
        _StatCell(value: timeStr, label: 'TIME', large: true),
        _Divider(),
        _StatCell(value: '$distKm km', label: 'DISTANCE'),
        _Divider(),
        _StatCell(value: speed, label: 'SPEED'),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.large = false,
  });

  final String value;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: large ? 26 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: Colors.white10,
    );
  }
}

// ─── Button row ───────────────────────────────────────────────────────────────

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({
    required this.isRecording,
    required this.isPaused,
    required this.activityType,
    required this.onSelectType,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  final bool isRecording;
  final bool isPaused;
  final ActivityType? activityType;
  final VoidCallback onSelectType;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    if (!isRecording) {
      // Idle: [activity type icon] [▶ START] [route placeholder]
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SmallFab(
            icon: activityType != null
                ? ActivityHelpers.getActivityIcon(activityType!)
                : Icons.add,
            onTap: onSelectType,
            tooltip: 'Change activity',
          ),
          _BigFab(
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFFFF5A1F),
            onTap: onStart,
          ),
          _SmallFab(
            icon: Icons.route_outlined,
            onTap: null,
            tooltip: 'Add route',
            disabled: true,
          ),
        ],
      );
    }

    // Recording: [pause/resume] [■ STOP] [···]
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SmallFab(
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          onTap: isPaused ? onResume : onPause,
          tooltip: isPaused ? 'Resume' : 'Pause',
        ),
        _BigFab(
          icon: Icons.stop_rounded,
          color: const Color(0xFFDC2626),
          onTap: onStop,
        ),
        _SmallFab(
          icon: Icons.more_horiz,
          onTap: null,
          disabled: true,
        ),
      ],
    );
  }
}

class _BigFab extends StatelessWidget {
  const _BigFab({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}

class _SmallFab extends StatelessWidget {
  const _SmallFab({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(
        icon,
        color: disabled ? Colors.white24 : Colors.white,
        size: 24,
      ),
    );

    if (disabled || onTap == null) return child;

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}

// ─── GPS denied sheet ─────────────────────────────────────────────────────────

Future<void> showGpsDeniedSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GpsDeniedSheet(),
  );
}

class _GpsDeniedSheet extends StatelessWidget {
  const _GpsDeniedSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
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
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off,
                color: Color(0xFFDC2626), size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Location Access Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable location in Settings to record your activity.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A1F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Open Settings',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white30, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
