import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/user.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_card.dart';
import 'package:snowtrak/widgets/skeleton.dart';

class ActivitiesFeedSliver extends StatelessWidget {
  const ActivitiesFeedSliver({
    super.key,
    required this.activityProvider,
    required this.user,
  });

  final ActivityProvider activityProvider;
  final User? user;

  @override
  Widget build(BuildContext context) {
    if (activityProvider.isLoading && activityProvider.activities.isEmpty) {
      return const SliverFillRemaining(
        child: SkeletonFeedList(),
      );
    }

    if (activityProvider.activities.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  200,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(SnowtrakSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.downhill_skiing,
                      size: 80,
                      color: context.colors.textTertiary,
                    ),
                    const SizedBox(height: SnowtrakSpacing.lg),
                    Text(
                      'No activities yet',
                      style: SnowtrakTypography.headlineMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SnowtrakSpacing.sm),
                    Text(
                      'Start recording your first skiing activity!',
                      style: SnowtrakTypography.bodyMedium.copyWith(
                        color: context.colors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SnowtrakSpacing.md,
              SnowtrakSpacing.xs,
              SnowtrakSpacing.md,
              SnowtrakSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 20,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: SnowtrakSpacing.sm),
                Text(
                  'Your activities',
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= activityProvider.activities.length - 3 &&
                    activityProvider.hasMore &&
                    !activityProvider.isLoadingMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    activityProvider.loadMore();
                  });
                }

                if (index >= activityProvider.activities.length) {
                  return const Padding(
                    padding: EdgeInsets.all(SnowtrakSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final activity = activityProvider.activities[index];
                final isCurrentUser = activity.userId == user?.id;
                final athleteName = isCurrentUser
                    ? (user?.firstName ?? user?.email.split('@')[0] ?? 'You')
                    : 'Athlete';

                return ActivityFeedCard(
                  activity: activity,
                  athleteName: athleteName,
                );
              },
              childCount: activityProvider.activities.length +
                  (activityProvider.isLoadingMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}
