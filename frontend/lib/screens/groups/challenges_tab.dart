import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/core/activity_helpers.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/groups/challenges_tab_widgets.dart';

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
      color: context.colors.primary,
      child: CustomScrollView(
        slivers: [
          // Activity type filter chips - skiing focused
          SliverToBoxAdapter(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(
                vertical: SnowtrakSpacing.sm,
                horizontal: SnowtrakSpacing.md,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _activityTypes.length,
                itemBuilder: (context, index) {
                  final activityType = _activityTypes[index];
                  final isSelected = _selectedActivityType == activityType;
                  final icon = ActivityHelpers.getActivityIcon(activityType);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: SnowtrakSpacing.sm),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected
                                ? context.colors.textOnPrimary
                                : context.colors.textSecondary,
                          ),
                          const SizedBox(width: SnowtrakSpacing.xs),
                          Text(
                            activityType.displayName,
                            style: SnowtrakTypography.labelMedium,
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedActivityType =
                              selected ? activityType : null;
                        });
                      },
                      selectedColor: context.colors.primary,
                      checkmarkColor: context.colors.textOnPrimary,
                      backgroundColor: context.colors.surfaceVariant,
                      labelStyle: SnowtrakTypography.labelMedium.copyWith(
                        color: isSelected
                            ? context.colors.textOnPrimary
                            : context.colors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SnowtrakRadius.round),
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
              margin: const EdgeInsets.all(SnowtrakSpacing.md),
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SnowtrakColors.primaryDark,
                    context.colors.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
                boxShadow: SnowtrakElevation.md,
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
                        color: context.colors.primary.withOpacity(0.3),
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
                        color: context.colors.warning.withOpacity(0.2),
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
                            horizontal: SnowtrakSpacing.md,
                            vertical: SnowtrakSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                          ),
                          child: Text(
                            'SYNTRAK',
                            style: SnowtrakTypography.labelSmall.copyWith(
                              color: context.colors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: SnowtrakSpacing.md),
                        Text(
                          'December Vertical Challenge',
                          style: SnowtrakTypography.displaySmall.copyWith(
                            color: context.colors.textOnPrimary,
                          ),
                        ),
                        const SizedBox(height: SnowtrakSpacing.sm),
                        Text(
                          'Complete 5,000m of vertical drop',
                          style: SnowtrakTypography.bodyMedium.copyWith(
                            color: context.colors.textOnPrimary.withOpacity(0.9),
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
            child: ChallengesDetailCard(
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
              padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement join challenge functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: SnowtrakSpacing.md,
                    ),
                  ),
                  child: const Text(
                    'Join Challenge',
                    style: SnowtrakTypography.labelLarge,
                  ),
                ),
              ),
            ),
          ),
          // Recommended challenges section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SnowtrakSpacing.md,
                SnowtrakSpacing.lg,
                SnowtrakSpacing.md,
                SnowtrakSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: SnowtrakSpacing.sm),
                  Text(
                    'Recommended For You',
                    style: SnowtrakTypography.headlineSmall.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
              child: Text(
                'Based on your skiing activities.',
                style: SnowtrakTypography.bodySmall.copyWith(
                  color: context.colors.textTertiary,
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
                padding: const EdgeInsets.all(SnowtrakSpacing.md),
                children: [
                  ChallengesRecommendedCard(
                    icon: ActivityHelpers.getActivityIcon(ActivityType.alpine),
                    title: 'December 400-Minute Alpine Challenge',
                    badge: '400\'',
                  ),
                  const SizedBox(width: SnowtrakSpacing.md),
                  ChallengesRecommendedCard(
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
                      color: context.colors.textTertiary,
                    ),
                    const SizedBox(height: SnowtrakSpacing.lg),
                    Text(
                      'No challenges available',
                      style: SnowtrakTypography.headlineMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SnowtrakSpacing.sm),
                    Text(
                      'Check back later for new skiing challenges',
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
        ],
      ),
    );
  }
}

