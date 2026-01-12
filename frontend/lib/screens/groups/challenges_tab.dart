import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';

class ChallengesTab extends StatefulWidget {
  const ChallengesTab({super.key});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  // Activity type filter - skiing focused
  ActivityType? _selectedActivityType;

  final List<ActivityType> _activityTypes = [
    ActivityType.alpine,
    ActivityType.crossCountry,
    ActivityType.freestyle,
    ActivityType.backcountry,
    ActivityType.snowboard,
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
          // Activity type filter chips - skiing focused
          SliverToBoxAdapter(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(
                vertical: SyntrakSpacing.sm,
                horizontal: SyntrakSpacing.md,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _activityTypes.length,
                itemBuilder: (context, index) {
                  final activityType = _activityTypes[index];
                  final isSelected = _selectedActivityType == activityType;
                  final icon = ActivityHelpers.getActivityIcon(activityType);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: SyntrakSpacing.sm),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected
                                ? SyntrakColors.textOnPrimary
                                : SyntrakColors.textSecondary,
                          ),
                          const SizedBox(width: SyntrakSpacing.xs),
                          Text(
                            activityType.displayName,
                            style: SyntrakTypography.labelMedium,
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedActivityType =
                              selected ? activityType : null;
                        });
                      },
                      selectedColor: SyntrakColors.primary,
                      checkmarkColor: SyntrakColors.textOnPrimary,
                      backgroundColor: SyntrakColors.surfaceVariant,
                      labelStyle: SyntrakTypography.labelMedium.copyWith(
                        color: isSelected
                            ? SyntrakColors.textOnPrimary
                            : SyntrakColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SyntrakRadius.round),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Featured challenge banner (placeholder)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(SyntrakSpacing.md),
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SyntrakColors.primaryDark,
                    SyntrakColors.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(SyntrakRadius.lg),
                boxShadow: SyntrakElevation.md,
              ),
              child: Stack(
                children: [
                  // Decorative shapes
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4500).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SyntrakSpacing.md,
                            vertical: SyntrakSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: SyntrakColors.accent,
                            borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                          ),
                          child: Text(
                            'SYNTRAK',
                            style: SyntrakTypography.labelSmall.copyWith(
                              color: SyntrakColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: SyntrakSpacing.md),
                        Text(
                          'December Vertical Challenge',
                          style: SyntrakTypography.displaySmall.copyWith(
                            color: SyntrakColors.textOnPrimary,
                          ),
                        ),
                        const SizedBox(height: SyntrakSpacing.sm),
                        Text(
                          'Complete 5,000m of vertical drop',
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.textOnPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Challenge card
          SliverToBoxAdapter(
            child: _buildChallengeCard(
              icon: ActivityHelpers.getActivityIcon(ActivityType.alpine),
              title: 'December Vertical Challenge',
              description: 'Complete 5,000m of vertical drop skiing.',
              duration: 'Dec 1 to Dec 31, 2025',
              badge: '5K',
            ),
          ),
          // Join button for featured challenge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement join challenge functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SyntrakColors.primary,
                    foregroundColor: SyntrakColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: SyntrakSpacing.md,
                    ),
                  ),
                  child: Text(
                    'Join Challenge',
                    style: SyntrakTypography.labelLarge,
                  ),
                ),
              ),
            ),
          ),
          // Recommended challenges section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SyntrakSpacing.md,
                SyntrakSpacing.lg,
                SyntrakSpacing.md,
                SyntrakSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: SyntrakColors.textSecondary,
                  ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  Text(
                    'Recommended For You',
                    style: SyntrakTypography.headlineSmall.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: Text(
                'Based on your skiing activities.',
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
              ),
            ),
          ),
          // Recommended challenges horizontal list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                children: [
                  _buildRecommendedChallengeCard(
                    icon: ActivityHelpers.getActivityIcon(ActivityType.alpine),
                    title: 'December 400-Minute Alpine Challenge',
                    badge: '400\'',
                  ),
                  const SizedBox(width: SyntrakSpacing.md),
                  _buildRecommendedChallengeCard(
                    icon: ActivityHelpers.getActivityIcon(ActivityType.crossCountry),
                    title: 'December Cross-Country 50K Challenge',
                    badge: '50K',
                  ),
                ],
              ),
            ),
          ),
          // Empty state if no challenges
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: SyntrakColors.textTertiary,
                    ),
                    const SizedBox(height: SyntrakSpacing.lg),
                    Text(
                      'No challenges available',
                      style: SyntrakTypography.headlineMedium.copyWith(
                        color: SyntrakColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.sm),
                    Text(
                      'Check back later for new skiing challenges',
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
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required String badge,
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
          // Challenge icon
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: SyntrakColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                ),
                child: Icon(
                  icon,
                  color: SyntrakColors.primary,
                  size: 30,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SyntrakColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: SyntrakColors.textOnPrimary,
                    size: 12,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SyntrakSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SyntrakColors.textPrimary,
                    borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                  ),
                  child: Text(
                    badge,
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: SyntrakColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Challenge details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs),
                Text(
                  description,
                  style: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs),
                Text(
                  duration,
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedChallengeCard({
    required IconData icon,
    required String title,
    required String badge,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: SyntrakColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                ),
                child: Icon(
                  icon,
                  color: SyntrakColors.primary,
                  size: 24,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SyntrakColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: SyntrakColors.textOnPrimary,
                    size: 10,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SyntrakSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SyntrakColors.textPrimary,
                    borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                  ),
                  child: Text(
                    badge,
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: SyntrakColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SyntrakSpacing.md),
          Text(
            title,
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

