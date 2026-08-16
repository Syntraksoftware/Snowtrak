import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_formatters.dart';

class ActivityFeedCardStatsRow extends StatelessWidget {
  const ActivityFeedCardStatsRow({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'Distance', value: activity.formattedDistance),
        _Stat(label: 'Time', value: formatMovingTimeSeconds(activity.duration)),
        _Stat(
          label: 'Elevation',
          value: '${activity.elevationGain.toStringAsFixed(0)}m',
        ),
        _Stat(label: 'Speed', value: activity.formattedSpeed),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: SnowtrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SnowtrakSpacing.xs / 2),
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
