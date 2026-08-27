import 'package:flutter/material.dart';
import 'package:snowtrak/core/activity_helpers.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/activities/activity_detail_screen.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_card_badges.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_card_header.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_card_map_thumbnail.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_card_stats_row.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: SnowtrakSpacing.md),
      child: Material(
        color: context.colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          side: BorderSide(color: context.colors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(activityId: activity.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActivityFeedCardHeader(
                activity: activity,
                athleteName: athleteName,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SnowtrakSpacing.md,
                  0,
                  SnowtrakSpacing.md,
                  SnowtrakSpacing.sm,
                ),
                child: Text(
                  activity.name?.isNotEmpty == true
                      ? activity.name!
                      : '${activity.type.displayName} Activity',
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
                child: ActivityFeedCardStatsRow(activity: activity),
              ),
              const SizedBox(height: SnowtrakSpacing.md),
              ActivityFeedCardMapThumbnail(
                locations: activity.locations,
                routeColor: activityColor,
                imageUrl: activity.thumbnailUrl,
              ),
              ActivityFeedCardBadges(activity: activity),
            ],
          ),
        ),
      ),
    );
  }
}
