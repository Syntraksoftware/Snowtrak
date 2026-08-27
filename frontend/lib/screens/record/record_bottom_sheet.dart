import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:snowtrak/core/activity_helpers.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/record/record_helpers.dart';
import 'package:snowtrak/services/location_service.dart';

// ─── Stats card (floating, collapsible) ──────────────────────────────────────

class RecordStatsCard extends StatefulWidget {
  const RecordStatsCard({
    super.key,
    required this.isRecording,
    required this.selectedActivityType,
    required this.locationService,
    required this.routePoints,
    required this.elapsedNotifier,
    required this.onSelectType,
  });

  final bool isRecording;
  final ActivityType? selectedActivityType;
  final LocationService locationService;
  final List<LatLng> routePoints;
  final ValueNotifier<Duration> elapsedNotifier;
  final VoidCallback onSelectType;

  @override
  State<RecordStatsCard> createState() => _RecordStatsCardState();
}

class _RecordStatsCardState extends State<RecordStatsCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _anim.forward() : _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.selectedActivityType;
    final icon = type != null ? ActivityHelpers.getActivityIcon(type) : null;
    final label = type?.displayName ?? 'Select Activity';

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SnowtrakColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: activity name + expand chevron
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        color: SnowtrakColors.primary, size: 15),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: SnowtrakTypography.labelLarge.copyWith(
                      color: SnowtrakColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: SnowtrakColors.textTertiary,
                    size: 22,
                  ),
                ],
              ),
            ),

            // Stats — animate in/out
            FadeTransition(
              opacity: _fade,
              child: SizeTransition(
                sizeFactor: _fade,
                axisAlignment: -1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: SnowtrakColors.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 18),
                      child: ValueListenableBuilder<Duration>(
                        valueListenable: widget.elapsedNotifier,
                        builder: (_, elapsed, __) => _StatsRow(
                          elapsed: elapsed,
                          locationService: widget.locationService,
                          routePoints: widget.routePoints,
                          isRecording: widget.isRecording,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Controls bar (pinned to bottom) ─────────────────────────────────────────

class RecordControls extends StatelessWidget {
  const RecordControls({
    super.key,
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
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        border: Border(
          top: BorderSide(color: SnowtrakColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(32, 16, 32, bottomPad + 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isRecording ? _recordingButtons() : _idleButtons(),
      ),
    );
  }

  List<Widget> _idleButtons() {
    return [
      _ControlButton(
        icon: activityType != null
            ? ActivityHelpers.getActivityIcon(activityType!)
            : Icons.add,
        label: activityType?.displayName ?? 'Activity',
        onTap: onSelectType,
        badged: activityType != null,
      ),
      _BigFab(
        icon: Icons.play_arrow_rounded,
        color: SnowtrakColors.primary,
        label: 'Start',
        labelColor: SnowtrakColors.primary,
        onTap: onStart,
      ),
      _ControlButton(
        icon: Icons.route_outlined,
        label: 'Add Route',
        onTap: null,
        disabled: true,
      ),
    ];
  }

  List<Widget> _recordingButtons() {
    return [
      _ControlButton(
        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        label: isPaused ? 'Resume' : 'Pause',
        onTap: isPaused ? onResume : onPause,
      ),
      _BigFab(
        icon: Icons.stop_rounded,
        color: SnowtrakColors.error,
        label: 'Stop',
        labelColor: SnowtrakColors.textSecondary,
        onTap: onStop,
      ),
      _ControlButton(
        icon: Icons.more_horiz,
        label: 'More',
        onTap: null,
        disabled: true,
      ),
    ];
  }
}

// ─── Internal widgets ─────────────────────────────────────────────────────────

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
    final speed = isRecording ? formatSpeedFromRouteTail(routePoints) : '--';

    return Row(
      children: [
        _StatCell(value: timeStr, label: 'Time', large: true),
        _VertDivider(),
        _StatCell(value: speed, label: 'Avg. speed (km/h)'),
        _VertDivider(),
        _StatCell(value: '$distKm km', label: 'Distance (km)'),
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
              color: SnowtrakColors.textPrimary,
              fontSize: large ? 28 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SnowtrakTypography.labelSmall.copyWith(
              color: SnowtrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: SnowtrakColors.divider,
      );
}

class _BigFab extends StatelessWidget {
  const _BigFab({
    required this.icon,
    required this.color,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: SnowtrakTypography.labelMedium.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.badged = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final bool badged;

  @override
  Widget build(BuildContext context) {
    final iconColor = disabled ? SnowtrakColors.textTertiary : SnowtrakColors.textSecondary;
    final labelColor = disabled ? SnowtrakColors.textTertiary : SnowtrakColors.textSecondary;

    final circle = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: SnowtrakColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(color: SnowtrakColors.divider),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        if (badged)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: SnowtrakColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: SnowtrakColors.surface, width: 1.5),
              ),
              child:
                  const Icon(Icons.check, color: Colors.white, size: 9),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(height: 6),
          Text(
            label,
            style: SnowtrakTypography.labelSmall.copyWith(
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GPS denied bottom sheet ──────────────────────────────────────────────────

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
        color: Colors.white,
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
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SnowtrakColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.location_off, color: SnowtrakColors.error, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Location Access Required',
            style: SnowtrakTypography.headlineSmall.copyWith(
              color: SnowtrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable location in Settings to record your activity.',
            textAlign: TextAlign.center,
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: SnowtrakColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: SnowtrakColors.primary,
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
            child: Text('Cancel',
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: SnowtrakColors.textTertiary,
                )),
          ),
        ],
      ),
    );
  }
}
