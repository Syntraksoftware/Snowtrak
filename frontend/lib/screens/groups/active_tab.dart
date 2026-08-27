import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/groups/active_tab_widgets.dart';

class ActiveTab extends StatefulWidget {
  const ActiveTab({super.key});

  @override
  State<ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends State<ActiveTab> {
  late final List<GroupChallengeItem> _challenges;

  @override
  void initState() {
    super.initState();
    _challenges = mockGroupChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: context.colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesignChallengeCard(),
            const SizedBox(height: SnowtrakSpacing.md),
            _buildChallengesSection(),
            _buildBanner(),
            const SizedBox(height: SnowtrakSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(SnowtrakSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYNTRAK SUBSCRIPTION',
            style: SnowtrakTypography.labelSmall.copyWith(
              color: context.colors.textTertiary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Text(
            'Design Your',
            style: SnowtrakTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              height: 1.1,
            ),
          ),
          Text(
            'Own Challenge',
            style: SnowtrakTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Text(
            'Rally your crew with a custom Group Challenge. Your game, your rules.',
            style: SnowtrakTypography.bodyLarge.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Start free trial coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SnowtrakRadius.round),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Your Free Trial',
                style: SnowtrakTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection() {
    return Container(
      padding: const EdgeInsets.all(SnowtrakSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available challenges',
            style: SnowtrakTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          ...List.generate(
            _challenges.length,
            (index) => ActiveGroupChallengeCard(challenge: _challenges[index]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'See All Challenges',
                style: SnowtrakTypography.labelLarge.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.lg),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            SnowtrakColors.primaryLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.downhill_skiing,
              size: 180,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SnowtrakSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnowtrakSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                  ),
                  child: Text(
                    'Challenge',
                    style: SnowtrakTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Snowtrak',
                      style: SnowtrakTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Winter Season 2026',
                      style: SnowtrakTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Row(
              children: [
                Icon(
                  Icons.ac_unit,
                  size: 20,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.landscape,
                  size: 20,
                  color: Colors.white.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
