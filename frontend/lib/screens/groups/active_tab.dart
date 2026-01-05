import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class ActiveTab extends StatefulWidget {
  const ActiveTab({super.key});

  @override
  State<ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends State<ActiveTab> {
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
          // Empty state or content will go here
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(SyntrakSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      size: 80,
                      color: SyntrakColors.textTertiary,
                    ),
                    const SizedBox(height: SyntrakSpacing.lg),
                    Text(
                      'No active groups',
                      style: SyntrakTypography.headlineMedium.copyWith(
                        color: SyntrakColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.sm),
                    Text(
                      'Join clubs or challenges to see them here',
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
}








