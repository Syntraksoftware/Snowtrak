import 'package:flutter/material.dart';
import 'package:snowtrak/core/activity_helpers.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_formatters.dart';

class ActivityFeedCardHeader extends StatelessWidget {
  const ActivityFeedCardHeader({
    super.key,
    required this.activity,
    this.athleteName,
  });

  final Activity activity;
  final String? athleteName;

  @override
  Widget build(BuildContext context) {
    final activityColor = ActivityHelpers.getActivityColor(activity.type);
    final activityIcon = ActivityHelpers.getActivityIcon(activity.type);

    return Padding(
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: SnowtrakColors.primary,
            child: Text(
              (athleteName ?? 'U')[0].toUpperCase(),
              style: SnowtrakTypography.headlineSmall.copyWith(
                color: SnowtrakColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: SnowtrakSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      athleteName ?? 'You',
                      style: SnowtrakTypography.bodyMedium.copyWith(
                        color: SnowtrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SnowtrakSpacing.xs),
                    if (!activity.isPublic)
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: SnowtrakColors.textTertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formatRelativeActivityTime(activity.startTime),
                      style: SnowtrakTypography.labelSmall.copyWith(
                        color: SnowtrakColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: SnowtrakSpacing.xs),
                    Icon(activityIcon, size: 14, color: activityColor),
                    const SizedBox(width: SnowtrakSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnowtrakSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: SnowtrakColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                      ),
                      child: Text(
                        'Phone',
                        style: SnowtrakTypography.labelSmall.copyWith(
                          color: SnowtrakColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
