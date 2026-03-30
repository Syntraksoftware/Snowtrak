import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class TrendingCard extends StatelessWidget {
  const TrendingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        0,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          side: BorderSide(
            color: SyntrakColors.divider,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SyntrakRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyntrakColors.accent.withOpacity(0.1),
                SyntrakColors.primary.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: SyntrakColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Text(
                      'Trending Now',
                      style: SyntrakTypography.headlineSmall.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SyntrakSpacing.md),
                Text(
                  'Join the community and see what\'s popular this week!',
                  style: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to trending/community
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SyntrakColors.accent,
                    foregroundColor: SyntrakColors.textOnPrimary,
                  ),
                  child: const Text('Explore'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
