import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user_stats.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/screens/profile/widgets/profile_layout_primitives.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_weekly_overview.dart';
import 'package:syntrak/screens/profile/widgets/profile_privacy_controls.dart';
import 'package:syntrak/ui/liquid/liquid_section_card.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

class ProfileHomeContent extends StatefulWidget {
  const ProfileHomeContent({super.key});

  @override
  State<ProfileHomeContent> createState() => _ProfileHomeContentState();
}

class _ProfileHomeContentState extends State<ProfileHomeContent> {
  int _periodIndex = 0; // 0 = Week, 1 = Year, 2 = All-time
  static const _accent = SnowtrakAuthTheme.brand;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final stats = provider.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: SyntrakSpacing.md),
        _identitySection(),
        const SizedBox(height: SyntrakSpacing.md),
        _performanceSection(stats),
        const SizedBox(height: SyntrakSpacing.md),
        _trainingSection(provider.activities),
        const SizedBox(height: SyntrakSpacing.md),
        _socialSection(),
        const SizedBox(height: SyntrakSpacing.md),
        _privacySection(),
        const SizedBox(height: SyntrakSpacing.xl),
      ],
    );
  }

  Widget _identitySection() {
    return LiquidSectionCard(
      icon: Icons.badge_outlined,
      title: 'Athlete identity & gear',
      subtitle: 'Bio, sports, and equipment',
      iconColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'Not set',
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          Wrap(
            spacing: SyntrakSpacing.sm,
            runSpacing: SyntrakSpacing.sm,
            children: const [
              ProfileChip(label: 'Alpine', icon: Icons.downhill_skiing, selected: true),
              ProfileChip(label: 'Cross-country', icon: Icons.nordic_walking),
              ProfileChip(label: 'Snowboard', icon: Icons.snowboarding),
            ],
          ),
          const SizedBox(height: SyntrakSpacing.md),
          Text(
            'Add a short bio to tell the community about your training.',
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textSecondary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          const ProfilePlaceholderBlock(
            icon: Icons.inventory_2_outlined,
            label: 'Virtual gear locker — track skis, boots, and binding mileage',
            height: 72,
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          Wrap(
            spacing: SyntrakSpacing.sm,
            runSpacing: SyntrakSpacing.sm,
            children: const [
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
    final timeStr = timeMin == null
        ? '—'
        : timeMin < 60
            ? '${timeMin}m'
            : '${(timeMin / 60).toStringAsFixed(1)}';

    final elev = stats == null ? '—' : [
      stats.weeklyElevGain,
      stats.yearlyElevGain,
      stats.allTimeElevGain,
    ][_periodIndex].toStringAsFixed(0);

    final sessions = stats == null ? '—' : [
      stats.weeklySessionCount,
      stats.yearlySessionCount,
      stats.allTimeSessionCount,
    ][_periodIndex].toString();

    return LiquidSectionCard(
      icon: Icons.insights_outlined,
      title: 'Performance summaries',
      subtitle: 'Distance, time, and personal records',
      iconColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SyntrakSpacing.sm,
            children: List.generate(periods.length, (i) => GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: ProfileChip(label: periods[i], selected: _periodIndex == i),
            )),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.straighten,
              label: 'Distance',
              value: dist,
              unit: 'km',
              accentColor: SyntrakColors.primary,
            ),
            right: ProfileMetricTile(
              icon: Icons.timer_outlined,
              label: 'Time',
              value: timeStr,
              unit: timeMin != null && timeMin >= 60 ? 'hr' : '',
              accentColor: SyntrakColors.primary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.terrain,
              label: 'Elevation',
              value: elev,
              unit: 'm',
              accentColor: SyntrakColors.primary,
            ),
            right: ProfileMetricTile(
              icon: Icons.directions_run_outlined,
              label: 'Sessions',
              value: sessions,
              unit: '',
              accentColor: SyntrakColors.primary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          const ProfilePlaceholderBlock(
            icon: Icons.emoji_events_outlined,
            label: 'Personal records — 5K, 10K, and segment bests',
            height: 72,
          ),
          const SizedBox(height: SyntrakSpacing.sm),
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
      iconColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isEmpty)
            const ProfilePlaceholderBlock(
              icon: Icons.map_outlined,
              label: 'No activities yet — record your first run!',
              height: 72,
            )
          else
            ...recent.map((a) => _RecentActivityRow(activity: a)),
          const SizedBox(height: SyntrakSpacing.sm),
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
      iconColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileMetricRow(
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
          const SizedBox(height: SyntrakSpacing.sm),
          const ProfileMetricRow(
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
          const SizedBox(height: SyntrakSpacing.md),
          _ChallengePreview(
            title: '100K vertical February',
            progress: 0,
          ),
          const SizedBox(height: SyntrakSpacing.sm),
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
      iconColor: _accent,
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
      padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SyntrakColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SyntrakRadius.md),
            ),
            child: const Icon(Icons.downhill_skiing, size: 18, color: SyntrakColors.primary),
          ),
          const SizedBox(width: SyntrakSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name ?? 'Activity',
                  style: SyntrakTypography.labelMedium.copyWith(color: SyntrakColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(activity.startTime),
                  style: SyntrakTypography.bodySmall.copyWith(color: SyntrakColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            activity.formattedDistance,
            style: SyntrakTypography.labelMedium.copyWith(color: SyntrakColors.textPrimary),
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
          style: SyntrakTypography.labelLarge.copyWith(
            color: SyntrakColors.textPrimary,
          ),
        ),
        const SizedBox(height: SyntrakSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(SyntrakRadius.round),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: SyntrakColors.surfaceVariant,
            color: SnowtrakAuthTheme.brand,
          ),
        ),
      ],
    );
  }
}
