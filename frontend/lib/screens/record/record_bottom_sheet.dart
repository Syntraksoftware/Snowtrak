import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/record/record_helpers.dart';
import 'package:syntrak/services/location_service.dart';

class RecordBottomSheet extends StatefulWidget {
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

  @override
  State<RecordBottomSheet> createState() => _RecordBottomSheetState();
}

class _RecordBottomSheetState extends State<RecordBottomSheet> {
  bool _isExpanded = true;

  static const _bg = Color(0xFF111827);
  static const _divider = Colors.white12;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRecording
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(isExpanded: _isExpanded, isRecording: widget.isRecording),
            const SizedBox(height: 16),
            if (!widget.isRecording) ...[
              _IdlePanel(
                selectedActivityType: widget.selectedActivityType,
                onSelectType: widget.onSelectType,
                onStart: widget.onStart,
              ),
            ] else ...[
              _CollapsedStats(
                elapsedNotifier: widget.elapsedNotifier,
                locationService: widget.locationService,
                routePoints: widget.routePoints,
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(color: _divider, height: 1),
                const SizedBox(height: 20),
                _ControlRow(
                  isPaused: widget.isPaused,
                  onPause: widget.onPause,
                  onResume: widget.onResume,
                  onStop: widget.onStop,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.isExpanded, required this.isRecording});
  final bool isExpanded;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (isRecording) ...[
          const Spacer(),
          Icon(
            isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            color: Colors.white30,
            size: 18,
          ),
        ],
      ],
    );
  }
}

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({
    required this.selectedActivityType,
    required this.onSelectType,
    required this.onStart,
  });

  final ActivityType? selectedActivityType;
  final VoidCallback onSelectType;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final hasType = selectedActivityType != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasType)
          GestureDetector(
            onTap: onSelectType,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ActivityHelpers.getActivityIcon(selectedActivityType!),
                  color: const Color(0xFFFF5A1F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedActivityType!.displayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, color: Colors.white30, size: 14),
              ],
            ),
          ),
        if (hasType) const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: hasType ? onStart : onSelectType,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A1F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              hasType ? 'Start Recording' : '+ Select Activity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedStats extends StatelessWidget {
  const _CollapsedStats({
    required this.elapsedNotifier,
    required this.locationService,
    required this.routePoints,
  });

  final ValueNotifier<Duration> elapsedNotifier;
  final LocationService locationService;
  final List<LatLng> routePoints;

  @override
  Widget build(BuildContext context) {
    final distanceKm =
        (locationService.calculateDistance() / 1000).toStringAsFixed(2);
    final speed = formatSpeedFromRouteTail(routePoints);

    return ValueListenableBuilder<Duration>(
      valueListenable: elapsedNotifier,
      builder: (_, elapsed, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatCell(
              value: formatRecordDuration(elapsed),
              label: 'Time',
              large: true,
            ),
            _StatDivider(),
            _StatCell(value: '$distanceKm km', label: 'Distance'),
            _StatDivider(),
            _StatCell(value: speed, label: 'Speed'),
          ],
        );
      },
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white12);
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
              fontSize: large ? 22 : 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CircleButton(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            label: isPaused ? 'Resume' : 'Pause',
            color: const Color(0xFF1F2937),
            iconColor: Colors.white,
            onTap: isPaused ? onResume : onPause,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onStop,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Stop',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: iconColor.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// GPS denied — shown as bottom sheet instead of AlertDialog.
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
            width: 40,
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
            child: const Icon(Icons.location_off, color: Color(0xFFDC2626), size: 30),
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
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // openAppSettings() called by caller after pop
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A1F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text('Open Settings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
