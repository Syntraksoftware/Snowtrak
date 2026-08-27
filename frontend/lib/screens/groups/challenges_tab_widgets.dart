import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Main vertical challenge card (detail row).
class ChallengesDetailCard extends StatelessWidget {
  const ChallengesDetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.duration,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final String duration;
  final String badge;

  @override
  Widget build(BuildContext context) {
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
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: SnowtrakColors.primaryLight.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                ),
                child: Icon(
                  icon,
                  color: context.colors.primary,
                  size: 30,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: context.colors.textOnPrimary,
                    size: 12,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnowtrakSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.textPrimary,
                    borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                  ),
                  child: Text(
                    badge,
                    style: SnowtrakTypography.labelSmall.copyWith(
                      color: context.colors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xs),
                Text(
                  description,
                  style: SnowtrakTypography.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xs),
                Text(
                  duration,
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal compact card in “Recommended for you”.
class ChallengesRecommendedCard extends StatelessWidget {
  const ChallengesRecommendedCard({
    super.key,
    required this.icon,
    required this.title,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        border: Border.all(color: context.colors.divider),
        boxShadow: SnowtrakElevation.sm,
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
                  color: SnowtrakColors.primaryLight.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                ),
                child: Icon(
                  icon,
                  color: context.colors.primary,
                  size: 24,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: context.colors.textOnPrimary,
                    size: 10,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnowtrakSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.textPrimary,
                    borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                  ),
                  child: Text(
                    badge,
                    style: SnowtrakTypography.labelSmall.copyWith(
                      color: context.colors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Text(
            title,
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: context.colors.textPrimary,
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
