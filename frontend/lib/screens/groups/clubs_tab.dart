import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

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
      color: SyntrakColors.primary,
      child: CustomScrollView(
        slivers: [
          // Customize Notifications section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(SyntrakSpacing.md),
              padding: const EdgeInsets.all(SyntrakSpacing.md),
              decoration: BoxDecoration(
                color: SyntrakColors.surfaceVariant,
                borderRadius: BorderRadius.circular(SyntrakRadius.lg),
                border: Border.all(color: SyntrakColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize Notifications',
                    style: SyntrakTypography.headlineSmall.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SyntrakSpacing.sm),
                  Text(
                    'Stay up to date. Turn on push notifications for your favorite clubs and mute the rest.',
                    style: SyntrakTypography.bodyMedium.copyWith(
                      color: SyntrakColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SyntrakSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement learn more functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SyntrakColors.primary,
                        foregroundColor: SyntrakColors.textOnPrimary,
                      ),
                      child: Text(
                        'Learn more',
                        style: SyntrakTypography.labelLarge,
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
                horizontal: SyntrakSpacing.md,
                vertical: SyntrakSpacing.sm,
              ),
              padding: const EdgeInsets.all(SyntrakSpacing.md),
              decoration: BoxDecoration(
                color: SyntrakColors.surface,
                borderRadius: BorderRadius.circular(SyntrakRadius.lg),
                border: Border.all(color: SyntrakColors.divider),
                boxShadow: SyntrakElevation.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Create your own Syntrak club',
                      style: SyntrakTypography.bodyLarge.copyWith(
                        color: SyntrakColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement create club functionality
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SyntrakColors.primary,
                      side: BorderSide(color: SyntrakColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: SyntrakSpacing.md,
                        vertical: SyntrakSpacing.sm,
                      ),
                    ),
                    child: Text(
                      'Create',
                      style: SyntrakTypography.labelMedium,
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
                SyntrakSpacing.md,
                SyntrakSpacing.md,
                SyntrakSpacing.md,
                SyntrakSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 18,
                        color: SyntrakColors.textSecondary,
                      ),
                      const SizedBox(width: SyntrakSpacing.sm),
                      Text(
                        'Skiing Clubs',
                        style: SyntrakTypography.headlineSmall.copyWith(
                          color: SyntrakColors.textPrimary,
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
                      style: SyntrakTypography.labelLarge.copyWith(
                        color: SyntrakColors.primary,
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
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Row(
        children: [
          // Club logo/icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: SyntrakColors.primaryLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: SyntrakColors.primary,
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
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: SyntrakColors.textSecondary,
                    ),
                    const SizedBox(width: SyntrakSpacing.xs),
                    Text(
                      _formatMemberCount(memberCount),
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SyntrakSpacing.xs / 2),
                Text(
                  location,
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs / 2),
                Text(
                  '$postCount posts',
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Join/Joined indicator
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: SyntrakColors.textTertiary,
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
