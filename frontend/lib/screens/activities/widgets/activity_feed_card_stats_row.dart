import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_formatters.dart';

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
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SyntrakSpacing.xs / 2),
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
}
