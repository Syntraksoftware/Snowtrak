import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

class ClubsTab extends StatefulWidget {
  const ClubsTab({super.key});

  @override
  State<ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<ClubsTab> {
  // List of skiing clubs
  final List<Map<String, dynamic>> _clubs = [
    {
      'name': 'Alpine Skiers',
      'memberCount': 10290,
      'location': 'Colorado, United States',
      'postCount': 231,
      'icon': Icons.downhill_skiing,
    },
    {
      'name': 'Powder Hounds',
      'memberCount': 8750,
      'location': 'Utah, United States',
      'postCount': 189,
      'icon': Icons.snowboarding,
    },
    {
      'name': 'Nordic Trackers',
      'memberCount': 5420,
      'location': 'Vermont, United States',
      'postCount': 156,
      'icon': Icons.nordic_walking,
    },
    {
      'name': 'Backcountry Explorers',
      'memberCount': 6230,
      'location': 'British Columbia, Canada',
      'postCount': 203,
      'icon': Icons.terrain,
    },
    {
      'name': 'Freestyle Skiers',
      'memberCount': 3890,
      'location': 'Switzerland',
      'postCount': 124,
      'icon': Icons.sports_gymnastics,
    },
    {
      'name': 'Mountain Riders',
      'memberCount': 7120,
      'location': 'Alps, France',
      'postCount': 178,
      'icon': Icons.landscape,
    },
    {
      'name': 'Slope Masters',
      'memberCount': 4560,
      'location': 'Austria',
      'postCount': 142,
      'icon': Icons.speed,
    },
    {
      'name': 'Snow Valley Club',
      'memberCount': 2980,
      'location': 'Japan',
      'postCount': 98,
      'icon': Icons.ac_unit,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh functionality
        await Future.delayed(const Duration(seconds: 1));
      },
      color: context.colors.primary,
      child: CustomScrollView(
        slivers: [
          // Customize Notifications section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(SnowtrakSpacing.md),
              padding: const EdgeInsets.all(SnowtrakSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
                border: Border.all(color: context.colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize Notifications',
                    style: SnowtrakTypography.headlineSmall.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SnowtrakSpacing.sm),
                  Text(
                    'Stay up to date. Turn on push notifications for your favorite clubs and mute the rest.',
                    style: SnowtrakTypography.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SnowtrakSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement learn more functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.textOnPrimary,
                      ),
                      child: const Text(
                        'Learn more',
                        style: SnowtrakTypography.labelLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Create club section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SnowtrakSpacing.md,
                vertical: SnowtrakSpacing.sm,
              ),
              padding: const EdgeInsets.all(SnowtrakSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
                border: Border.all(color: context.colors.divider),
                boxShadow: SnowtrakElevation.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Create your own Snowtrak club',
                      style: SnowtrakTypography.bodyLarge.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: SnowtrakSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement create club functionality
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(color: context.colors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnowtrakSpacing.md,
                        vertical: SnowtrakSpacing.sm,
                      ),
                    ),
                    child: const Text(
                      'Create',
                      style: SnowtrakTypography.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clubs list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SnowtrakSpacing.md,
                SnowtrakSpacing.md,
                SnowtrakSpacing.md,
                SnowtrakSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 18,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: SnowtrakSpacing.sm),
                      Text(
                        'Skiing Clubs',
                        style: SnowtrakTypography.headlineSmall.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Show all clubs
                    },
                    child: Text(
                      'All clubs',
                      style: SnowtrakTypography.labelLarge.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clubs list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final club = _clubs[index];
                return _buildClubCard(
                  name: club['name'] as String,
                  memberCount: club['memberCount'] as int,
                  location: club['location'] as String,
                  postCount: club['postCount'] as int,
                  icon: club['icon'] as IconData,
                );
              },
              childCount: _clubs.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard({
    required String name,
    required int memberCount,
    required String location,
    required int postCount,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SnowtrakSpacing.md,
        vertical: SnowtrakSpacing.sm,
      ),
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        border: Border.all(color: context.colors.divider),
        boxShadow: SnowtrakElevation.sm,
      ),
      child: Row(
        children: [
          // Club logo/icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: SnowtrakColors.primaryLight.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: context.colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          // Club details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: SnowtrakSpacing.xs),
                    Text(
                      _formatMemberCount(memberCount),
                      style: SnowtrakTypography.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SnowtrakSpacing.xs / 2),
                Text(
                  location,
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xs / 2),
                Text(
                  '$postCount posts',
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Join/Joined indicator
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: context.colors.textTertiary,
            onPressed: () {
              // TODO: Navigate to club detail
            },
          ),
        ],
      ),
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K Members';
    }
    return '$count Members';
  }
}
