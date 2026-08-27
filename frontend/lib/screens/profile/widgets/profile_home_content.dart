import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/user_stats.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_formatters.dart';
import 'package:snowtrak/screens/profile/widgets/profile_layout_primitives.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_weekly_overview.dart';
import 'package:snowtrak/screens/profile/widgets/profile_privacy_controls.dart';
import 'package:snowtrak/ui/liquid/liquid_section_card.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

class ProfileHomeContent extends StatefulWidget {
  const ProfileHomeContent({super.key, this.isOwnProfile = true});

  /// False when rendering somebody else's profile.
  ///
  /// ActivityProvider only ever holds the signed-in user's activities and
  /// stats, so reading it for another person would print your numbers under
  /// their name. Their sections render empty until a per-user stats endpoint
  /// exists. The privacy card is dropped outright -- those toggles are your
  /// own settings and do not belong on someone else's page.
  final bool isOwnProfile;

  @override
  State<ProfileHomeContent> createState() => _ProfileHomeContentState();
}

class _ProfileHomeContentState extends State<ProfileHomeContent> {
  int _periodIndex = 0; // 0 = Week, 1 = Year, 2 = All-time

  @override
  Widget build(BuildContext context) {
    final provider =
        widget.isOwnProfile ? context.watch<ActivityProvider>() : null;
    final stats = provider?.stats;
    final activities = provider?.activities ?? const <Activity>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: SnowtrakSpacing.md),
        _identitySection(),
        const SizedBox(height: SnowtrakSpacing.md),
        _performanceSection(stats),
        const SizedBox(height: SnowtrakSpacing.md),
        _trainingSection(activities),
        const SizedBox(height: SnowtrakSpacing.md),
        _socialSection(),
        if (widget.isOwnProfile) ...[
          const SizedBox(height: SnowtrakSpacing.md),
          _privacySection(),
        ],
        const SizedBox(height: SnowtrakSpacing.xl),
      ],
    );
  }

  Widget _identitySection() {
    return LiquidSectionCard(
      icon: Icons.badge_outlined,
      title: 'Athlete identity & gear',
      subtitle: 'Bio, sports, and equipment',
      iconColor: context.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'Not set',
          ),
          const SizedBox(height: SnowtrakSpacing.sm),
          const Wrap(
            spacing: SnowtrakSpacing.sm,
            runSpacing: SnowtrakSpacing.sm,
            children: [
              ProfileChip(label: 'Alpine', icon: Icons.downhill_skiing, selected: true),
              ProfileChip(label: 'Cross-country', icon: Icons.nordic_walking),
              ProfileChip(label: 'Snowboard', icon: Icons.snowboarding),
            ],
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Text(
            widget.isOwnProfile
                ? 'Add a short bio to tell the community about your training.'
                : 'No bio yet.',
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          const ProfilePlaceholderBlock(
            icon: Icons.inventory_2_outlined,
            label: 'Virtual gear locker — track skis, boots, and binding mileage',
            height: 72,
          ),
          const SizedBox(height: SnowtrakSpacing.sm),
          const Wrap(
            spacing: SnowtrakSpacing.sm,
            runSpacing: SnowtrakSpacing.sm,
            children: [
              ProfileChip(label: 'Alpine Club', icon: Icons.groups_outlined),
              ProfileChip(label: 'Corp Team', icon: Icons.business_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceSection(UserStats? stats) {
    final periods = ['Week', 'Year', 'All-time'];
    final dist = stats == null ? '—' : [
      stats.weeklyDistanceKm,
      stats.yearlyDistanceKm,
      stats.allTimeDistanceKm,
    ][_periodIndex].toStringAsFixed(1);

    final timeMin = stats == null ? null : [
      stats.weeklyTimeMin,
      stats.yearlyTimeMin,
      stats.allTimeTimeMin,
    ][_periodIndex];
    final timeStr = timeMin == null ? '—' : formatDurationMinutes(timeMin);

    final elev = stats == null ? '—' : formatElevation([
      stats.weeklyElevGain,
      stats.yearlyElevGain,
      stats.allTimeElevGain,
    ][_periodIndex]);

    final sessions = stats == null ? '—' : [
      stats.weeklySessionCount,
      stats.yearlySessionCount,
      stats.allTimeSessionCount,
    ][_periodIndex].toString();

    return LiquidSectionCard(
      icon: Icons.insights_outlined,
      title: 'Performance summaries',
      subtitle: 'Distance, time, and personal records',
      iconColor: context.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SnowtrakSpacing.sm,
            children: List.generate(periods.length, (i) => GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: ProfileChip(label: periods[i], selected: _periodIndex == i),
            )),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.straighten,
              label: 'Distance',
              value: dist,
              unit: 'km',
              accentColor: context.colors.primary,
            ),
            right: ProfileMetricTile(
              icon: Icons.timer_outlined,
              label: 'Time',
              value: timeStr,
              unit: '',
              accentColor: context.colors.primary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.sm),
          ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.terrain,
              label: 'Elevation',
              value: elev,
              unit: '',
              accentColor: context.colors.primary,
            ),
            right: ProfileMetricTile(
              icon: Icons.directions_run_outlined,
              label: 'Sessions',
              value: sessions,
              unit: '',
              accentColor: context.colors.primary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          const ProfilePlaceholderBlock(
            icon: Icons.emoji_events_outlined,
            label: 'Personal records — 5K, 10K, and segment bests',
            height: 72,
          ),
          const SizedBox(height: SnowtrakSpacing.sm),
          const ProfilePlaceholderBlock(
            icon: Icons.show_chart,
            label: 'Fitness trends — fitness, fatigue, and form',
            height: 88,
          ),
        ],
      ),
    );
  }

  Widget _trainingSection(List<Activity> activities) {
    final recent = activities.take(3).toList();
    return LiquidSectionCard(
      icon: Icons.history,
      title: 'Training history',
      subtitle: 'Recent workouts and consistency',
      iconColor: context.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isEmpty)
            ProfilePlaceholderBlock(
              icon: Icons.map_outlined,
              label: widget.isOwnProfile
                  ? 'No activities yet — record your first run!'
                  : 'Activities are not shared yet.',
              height: 72,
            )
          else
            ...recent.map((a) => _RecentActivityRow(activity: a)),
          const SizedBox(height: SnowtrakSpacing.sm),
          TwelveWeekSparkline(activities: activities),
        ],
      ),
    );
  }

  Widget _socialSection() {
    return LiquidSectionCard(
      icon: Icons.people_outline,
      title: 'Social & community',
      subtitle: 'Followers, kudos, and challenges',
      iconColor: context.colors.primary,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.person_add_outlined,
              label: 'Following',
              value: '—',
              unit: '',
            ),
            right: ProfileMetricTile(
              icon: Icons.group_outlined,
              label: 'Followers',
              value: '—',
              unit: '',
            ),
          ),
          SizedBox(height: SnowtrakSpacing.sm),
          ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.thumb_up_outlined,
              label: 'Kudos',
              value: '—',
              unit: '',
            ),
            right: ProfileMetricTile(
              icon: Icons.chat_bubble_outline,
              label: 'Comments',
              value: '—',
              unit: '',
            ),
          ),
          SizedBox(height: SnowtrakSpacing.md),
          _ChallengePreview(
            title: '100K vertical February',
            progress: 0,
          ),
          SizedBox(height: SnowtrakSpacing.sm),
          _ChallengePreview(
            title: 'Gran Fondo prep',
            progress: 0,
          ),
        ],
      ),
    );
  }

  Widget _privacySection() {
    return LiquidSectionCard(
      icon: Icons.shield_outlined,
      title: 'Privacy controls',
      subtitle: 'Location data and visibility',
      iconColor: context.colors.primary,
      child: const ProfilePrivacyControls(),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SnowtrakSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SnowtrakRadius.md),
            ),
            child: Icon(Icons.downhill_skiing, size: 18, color: context.colors.primary),
          ),
          const SizedBox(width: SnowtrakSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name ?? 'Activity',
                  style: SnowtrakTypography.labelMedium.copyWith(color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(activity.startTime),
                  style: SnowtrakTypography.bodySmall.copyWith(color: context.colors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            activity.formattedDistance,
            style: SnowtrakTypography.labelMedium.copyWith(color: context.colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ChallengePreview extends StatelessWidget {
  const _ChallengePreview({
    required this.title,
    required this.progress,
  });

  final String title;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SnowtrakTypography.labelLarge.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(SnowtrakRadius.round),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: context.colors.surfaceVariant,
            color: context.colors.primary,
          ),
        ),
      ],
    );
  }
}
