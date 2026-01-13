import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class ActiveTab extends StatefulWidget {
  const ActiveTab({super.key});

  @override
  State<ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends State<ActiveTab> {
  // Mock data for challenges
  final List<_ChallengeData> _challenges = [
    _ChallengeData(
      id: '1',
      title: 'January Vertical Challenge',
      description: 'Accumulate 10,000m of vertical descent in January',
      dateRange: 'Jan 1, 2026 to Jan 31, 2026',
      badgeText: '10K',
      badgeColor: const Color(0xFFE65100),
      icon: Icons.terrain,
    ),
    _ChallengeData(
      id: '2',
      title: 'Winter Explorer Challenge',
      description: 'Visit 5 different ski resorts this season',
      dateRange: 'Dec 1, 2025 to Mar 31, 2026',
      badgeText: '5',
      badgeColor: const Color(0xFF1565C0),
      icon: Icons.explore,
    ),
    _ChallengeData(
      id: '3',
      title: 'Speed Demon Challenge',
      description: 'Record a run with max speed over 80 km/h',
      dateRange: 'Jan 1, 2026 to Jan 31, 2026',
      badgeText: '80',
      badgeColor: const Color(0xFFC62828),
      icon: Icons.speed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: SyntrakColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Design Your Own Challenge Card
            _buildDesignChallengeCard(),

            const SizedBox(height: SyntrakSpacing.md),

            // Available Challenges Section
            _buildChallengesSection(),

            // Banner
            _buildBanner(),

            const SizedBox(height: SyntrakSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'SYNTRAK SUBSCRIPTION',
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textTertiary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),

          // Title
          Text(
            'Design Your',
            style: SyntrakTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SyntrakColors.textPrimary,
              height: 1.1,
            ),
          ),
          Text(
            'Own Challenge',
            style: SyntrakTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SyntrakColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),

          // Description
          Text(
            'Rally your crew with a custom Group Challenge. Your game, your rules.',
            style: SyntrakTypography.bodyLarge.copyWith(
              color: SyntrakColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.lg),

          // CTA Button
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
                backgroundColor: SyntrakColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SyntrakRadius.round),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Your Free Trial',
                style: SyntrakTypography.labelLarge.copyWith(
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
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Available challenges',
            style: SyntrakTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),

          // Challenges list
          ...List.generate(
            _challenges.length,
            (index) => _ChallengeCard(challenge: _challenges[index]),
          ),

          // See all link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigate to all challenges
              },
              child: Text(
                'See All Challenges',
                style: SyntrakTypography.labelLarge.copyWith(
                  color: SyntrakColors.primary,
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
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.lg),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF3949AB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.downhill_skiing,
              size: 180,
              color: Colors.white.withOpacity(0.1),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SyntrakSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                  ),
                  child: Text(
                    'Challenge',
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Title and subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SynTrak',
                      style: SyntrakTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Winter Season 2026',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mountain icons decoration
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

// Data models
class _ChallengeData {
  final String id;
  final String title;
  final String description;
  final String dateRange;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;

  _ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.dateRange,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
  });
}

// Challenge Card Widget
class _ChallengeCard extends StatelessWidget {
  final _ChallengeData challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${challenge.title} details coming soon!'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            _ChallengeBadge(
              text: challenge.badgeText,
              color: challenge.badgeColor,
              icon: challenge.icon,
            ),
            const SizedBox(width: SyntrakSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    challenge.title,
                    style: SyntrakTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SyntrakColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description with icon
                  Row(
                    children: [
                      Icon(
                        challenge.icon,
                        size: 14,
                        color: SyntrakColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          challenge.description,
                          style: SyntrakTypography.bodySmall.copyWith(
                            color: SyntrakColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date range
                  Text(
                    challenge.dateRange,
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: SyntrakColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Challenge Badge Widget
class _ChallengeBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _ChallengeBadge({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Starburst pattern
          CustomPaint(
            size: const Size(70, 70),
            painter: _StarburstPainter(color: Colors.white.withOpacity(0.15)),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Starburst pattern painter for badges
class _StarburstPainter extends CustomPainter {
  final Color color;

  _StarburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    const points = 12;
    final innerRadius = size.width * 0.25;
    final outerRadius = size.width * 0.45;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * 3.14159 / points) - 3.14159 / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);  double _cos(double angle) {
    return (angle == 0)
        ? 1
        : (angle == 3.14159 / 2)
            ? 0
            : (angle == 3.14159)
                ? -1
                : (angle == 3 * 3.14159 / 2)
                    ? 0
                    : _cosInternal(angle);
  }

  double _sin(double angle) {
    return (angle == 0)
        ? 0
        : (angle == 3.14159 / 2)
            ? 1
            : (angle == 3.14159)
                ? 0
                : (angle == 3 * 3.14159 / 2)
                    ? -1
                    : _sinInternal(angle);
  }

  double _cosInternal(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  double _sinInternal(double x) {
    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
