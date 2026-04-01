import 'package:flutter/material.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_card_badges.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_card_header.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_card_map_thumbnail.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_card_stats_row.dart';

/// Single activity row in the home feed (card with stats and route preview).
class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({
    super.key,
    required this.activity,
    this.athleteName,
  });

  final Activity activity;
  final String? athleteName;

  @override
  Widget build(BuildContext context) {
    final activityColor = ActivityHelpers.getActivityColor(activity.type);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(color: SyntrakColors.divider, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: SyntrakSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(activityId: activity.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActivityFeedCardHeader(
              activity: activity,
              athleteName: athleteName,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SyntrakSpacing.md,
                0,
                SyntrakSpacing.md,
                SyntrakSpacing.sm,
              ),
              child: Text(
                activity.name?.isNotEmpty == true
                    ? activity.name!
                    : '${activity.type.displayName} Activity',
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: SyntrakColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: ActivityFeedCardStatsRow(activity: activity),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ActivityFeedCardMapThumbnail(
              locations: activity.locations,
              routeColor: activityColor,
            ),
            ActivityFeedCardBadges(activity: activity),
          ],
        ),
      ),
    );
  }
}
