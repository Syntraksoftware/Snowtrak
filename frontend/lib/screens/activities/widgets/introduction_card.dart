import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class IntroductionCard extends StatelessWidget {
  const IntroductionCard({super.key});

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
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New to Syntrak?',
                      style: SyntrakTypography.headlineSmall.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.sm),
                    Text(
                      'Get started and explore new features. Track your skiing activities, connect with friends, and discover amazing trails!',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.md),
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(SyntrakRadius.md),
                          color: SyntrakColors.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.downhill_skiing,
                          size: 30,
                          color: SyntrakColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New to Syntrak?',
                          style: SyntrakTypography.headlineSmall.copyWith(
                            color: SyntrakColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SyntrakSpacing.sm),
                        Text(
                          'Get started and explore new features. Track your skiing activities, connect with friends, and discover amazing trails!',
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.md),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SyntrakRadius.md),
                      color: SyntrakColors.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.downhill_skiing,
                      size: 40,
                      color: SyntrakColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
