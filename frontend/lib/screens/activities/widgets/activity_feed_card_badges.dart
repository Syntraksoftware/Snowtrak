import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';

class ActivityFeedCardBadges extends StatelessWidget {
  const ActivityFeedCardBadges({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    if (!_hasBadges(activity)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      child: Wrap(
        spacing: SyntrakSpacing.sm,
        runSpacing: SyntrakSpacing.xs,
        children: _buildBadges(activity),
      ),
    );
  }

  bool _hasBadges(Activity activity) {
    return activity.distance > 5000 || activity.elevationGain > 500;
  }

  List<Widget> _buildBadges(Activity activity) {
    final badges = <Widget>[];
    if (activity.distance > 10000) {
      badges.add(
        _Badge(
          icon: Icons.emoji_events,
          label: 'Long',
          color: SyntrakColors.accent,
        ),
      );
    }
    if (activity.elevationGain > 1000) {
      badges.add(
        _Badge(
          icon: Icons.trending_up,
          label: 'Elevation',
          color: SyntrakColors.secondary,
        ),
      );
    }
    if (activity.distance > 5000 && activity.elevationGain > 500) {
      badges.add(
        _Badge(
          icon: Icons.star,
          label: 'PR',
          color: SyntrakColors.accent,
        ),
      );
    }
    return badges;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.sm,
        vertical: SyntrakSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SyntrakRadius.md),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: SyntrakSpacing.xs / 2),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
