import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Mock challenge row for the Active tab.
class GroupChallengeItem {
  const GroupChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dateRange,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String dateRange;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
}

List<GroupChallengeItem> mockGroupChallenges() {
  return const [
    GroupChallengeItem(
      id: '1',
      title: 'January Vertical Challenge',
      description: 'Accumulate 10,000m of vertical descent in January',
      dateRange: 'Jan 1, 2026 to Jan 31, 2026',
      badgeText: '10K',
      badgeColor: Color(0xFFE65100),
      icon: Icons.terrain,
    ),
    GroupChallengeItem(
      id: '2',
      title: 'Winter Explorer Challenge',
      description: 'Visit 5 different ski resorts this season',
      dateRange: 'Dec 1, 2025 to Mar 31, 2026',
      badgeText: '5',
      badgeColor: Color(0xFF1565C0),
      icon: Icons.explore,
    ),
    GroupChallengeItem(
      id: '3',
      title: 'Speed Demon Challenge',
      description: 'Record a run with max speed over 80 km/h',
      dateRange: 'Jan 1, 2026 to Jan 31, 2026',
      badgeText: '80',
      badgeColor: Color(0xFFC62828),
      icon: Icons.speed,
    ),
  ];
}

class ActiveGroupChallengeCard extends StatelessWidget {
  const ActiveGroupChallengeCard({super.key, required this.challenge});

  final GroupChallengeItem challenge;

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
            ActiveChallengeBadge(
              text: challenge.badgeText,
              color: challenge.badgeColor,
              icon: challenge.icon,
            ),
            const SizedBox(width: SyntrakSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: SyntrakTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SyntrakColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
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

class ActiveChallengeBadge extends StatelessWidget {
  const ActiveChallengeBadge({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

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
          CustomPaint(
            size: const Size(70, 70),
            painter: ActiveStarburstPainter(color: Colors.white.withOpacity(0.15)),
          ),
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

class ActiveStarburstPainter extends CustomPainter {
  ActiveStarburstPainter({required this.color});

  final Color color;

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
      final angle = (i * math.pi / points) - math.pi / 2;
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
