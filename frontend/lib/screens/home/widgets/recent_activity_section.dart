import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_formatters.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Compact activity rows under the statistics carousel — 74pt cards, per
/// `07 · Screens — Home`.
// ponytail: the design calls this "Friends' Recent Activity"; there is no
// following-feed endpoint yet, so it shows the activities feed we do have.
// Rename + swap the source when the social feed lands.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    super.key,
    required this.activities,
    this.onSeeAll,
    this.onOpenActivity,
  });

  final List<Activity> activities;
  final VoidCallback? onSeeAll;
  final void Function(Activity activity)? onOpenActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StSectionHeader(
          title: 'Recent activity',
          actionLabel: 'See all',
          onAction: onSeeAll,
        ),
        const SizedBox(height: SnowtrakSpacing.smd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
          child: Column(
            children: [
              if (activities.isEmpty)
                const _EmptyRow()
              else
                for (final activity in activities.take(5)) ...[
                  _ActivityRow(
                    activity: activity,
                    onTap: () => onOpenActivity?.call(activity),
                  ),
                  const SizedBox(height: SnowtrakSpacing.smd),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, this.onTap});

  final Activity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = activity.name ?? 'Session';

    return StCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                title.characters.first.toUpperCase(),
                style: SnowtrakTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: SnowtrakSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnowtrakTypography.labelLarge.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatRelativeActivityTime(activity.startTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnowtrakTypography.labelMedium.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SnowtrakSpacing.sm),
            StChipButton(label: 'View', onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return StCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          StIcon(StIcons.ski, size: 18, color: context.colors.textTertiary),
          const SizedBox(width: SnowtrakSpacing.smd),
          Expanded(
            child: Text(
              'No sessions yet. Hit Record to log your first run.',
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
