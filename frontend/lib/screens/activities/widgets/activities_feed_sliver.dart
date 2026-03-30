import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/screens/activities/widgets/activity_feed_card.dart';

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
        child: Center(child: CircularProgressIndicator()),
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
                padding: const EdgeInsets.all(SyntrakSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.downhill_skiing,
                      size: 80,
                      color: SyntrakColors.textTertiary,
                    ),
                    const SizedBox(height: SyntrakSpacing.lg),
                    Text(
                      'No activities yet',
                      style: SyntrakTypography.headlineMedium.copyWith(
                        color: SyntrakColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.sm),
                    Text(
                      'Start recording your first skiing activity!',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textTertiary,
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
              SyntrakSpacing.md,
              SyntrakSpacing.lg,
              SyntrakSpacing.md,
              SyntrakSpacing.md,
            ),
            child: Text(
              'Your Activities',
              style: SyntrakTypography.headlineMedium.copyWith(
                color: SyntrakColors.textPrimary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
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
                    padding: EdgeInsets.all(SyntrakSpacing.lg),
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
