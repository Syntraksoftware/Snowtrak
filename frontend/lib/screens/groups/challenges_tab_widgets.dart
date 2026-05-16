import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

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
