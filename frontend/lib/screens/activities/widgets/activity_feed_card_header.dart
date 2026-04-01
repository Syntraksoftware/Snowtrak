import 'package:flutter/material.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_formatters.dart';

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
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: SyntrakColors.primary,
            child: Text(
              (athleteName ?? 'U')[0].toUpperCase(),
              style: SyntrakTypography.headlineSmall.copyWith(
                color: SyntrakColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: SyntrakSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      athleteName ?? 'You',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.xs),
                    if (!activity.isPublic)
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: SyntrakColors.textTertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formatRelativeActivityTime(activity.startTime),
                      style: SyntrakTypography.labelSmall.copyWith(
                        color: SyntrakColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.xs),
                    Icon(activityIcon, size: 14, color: activityColor),
                    const SizedBox(width: SyntrakSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SyntrakSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: SyntrakColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                      ),
                      child: Text(
                        'Phone',
                        style: SyntrakTypography.labelSmall.copyWith(
                          color: SyntrakColors.textTertiary,
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
