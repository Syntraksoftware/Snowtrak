import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/profile/widgets/profile_layout_primitives.dart';
import 'package:syntrak/screens/profile/widgets/profile_privacy_controls.dart';
import 'package:syntrak/ui/liquid/liquid_section_card.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

/// Scrollable profile sections — layout placeholders until features ship.
class ProfileHomeContent extends StatelessWidget {
  const ProfileHomeContent({super.key});

  static const _accent = SnowtrakAuthTheme.brand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: SyntrakSpacing.md),
        _identitySection(),
        const SizedBox(height: SyntrakSpacing.md),
        _performanceSection(),
        const SizedBox(height: SyntrakSpacing.md),
        _trainingSection(),
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

  Widget _performanceSection() {
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
            children: const [
              ProfileChip(label: 'Week', selected: true),
              ProfileChip(label: 'Year'),
              ProfileChip(label: 'All-time'),
            ],
          ),
          const SizedBox(height: SyntrakSpacing.md),
          const ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.straighten,
              label: 'Distance',
              value: '—',
              unit: 'km',
            ),
            right: ProfileMetricTile(
              icon: Icons.timer_outlined,
              label: 'Time',
              value: '—',
              unit: 'hr',
            ),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          const ProfileMetricRow(
            left: ProfileMetricTile(
              icon: Icons.terrain,
              label: 'Elevation',
              value: '—',
              unit: 'm',
            ),
            right: ProfileMetricTile(
              icon: Icons.emoji_events_outlined,
              label: 'PRs',
              value: '—',
              unit: '',
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

  Widget _trainingSection() {
    return LiquidSectionCard(
      icon: Icons.history,
      title: 'Training history',
      subtitle: 'Recent workouts and consistency',
      iconColor: _accent,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfilePlaceholderBlock(
            icon: Icons.map_outlined,
            label: 'Recent activity feed with routes and metrics',
            height: 88,
          ),
          SizedBox(height: SyntrakSpacing.sm),
          ProfilePlaceholderBlock(
            icon: Icons.calendar_month_outlined,
            label: 'Training calendar — weekly volume at a glance',
            height: 88,
          ),
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
