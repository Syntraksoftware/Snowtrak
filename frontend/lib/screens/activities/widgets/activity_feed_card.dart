import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:syntrak/screens/activities/widgets/activity_route_preview_painter.dart';

/// Single activity row in the home feed (card with stats and route preview).
class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({
    super.key,
    required this.activity,
    this.athleteName,
  });

  final Activity activity;
  final String? athleteName;

  @override
  Widget build(BuildContext context) {
    final activityColor = ActivityHelpers.getActivityColor(activity.type);
    final activityIcon = ActivityHelpers.getActivityIcon(activity.type);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(color: SyntrakColors.divider, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: SyntrakSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(activityId: activity.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(SyntrakSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: SyntrakColors.primary,
                    child: Text(
                      (athleteName ?? 'U')[0].toUpperCase(),
                      style: SyntrakTypography.headlineSmall.copyWith(
                        color: SyntrakColors.textOnPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              athleteName ?? 'You',
                              style: SyntrakTypography.bodyMedium.copyWith(
                                color: SyntrakColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: SyntrakSpacing.xs),
                            if (!activity.isPublic)
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: SyntrakColors.textTertiary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatRelativeTime(activity.startTime),
                              style: SyntrakTypography.labelSmall.copyWith(
                                color: SyntrakColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: SyntrakSpacing.xs),
                            Icon(activityIcon, size: 14, color: activityColor),
                            const SizedBox(width: SyntrakSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SyntrakSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: SyntrakColors.surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(SyntrakRadius.sm),
                              ),
                              child: Text(
                                'Phone',
                                style: SyntrakTypography.labelSmall.copyWith(
                                  color: SyntrakColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SyntrakSpacing.md,
                0,
                SyntrakSpacing.md,
                SyntrakSpacing.sm,
              ),
              child: Text(
                activity.name?.isNotEmpty == true
                    ? activity.name!
                    : '${activity.type.displayName} Activity',
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: SyntrakColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Distance', activity.formattedDistance),
                  _buildStat('Time', _formatMovingTime(activity.duration)),
                  _buildStat(
                    'Elevation',
                    '${activity.elevationGain.toStringAsFixed(0)}m',
                  ),
                  _buildStat('Speed', activity.formattedSpeed),
                ],
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            if (activity.locations.isNotEmpty)
              _buildMapThumbnail(activity.locations, activityColor)
            else
              Container(
                height: 200,
                color: SyntrakColors.surfaceVariant,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: SyntrakColors.textTertiary,
                        size: 40,
                      ),
                      const SizedBox(height: SyntrakSpacing.sm),
                      Text(
                        'No route data',
                        style: SyntrakTypography.bodySmall.copyWith(
                          color: SyntrakColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasBadges(activity))
              Padding(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                child: Wrap(
                  spacing: SyntrakSpacing.sm,
                  runSpacing: SyntrakSpacing.xs,
                  children: _buildBadges(activity),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    return DateFormat('MMM d').format(date);
  }

  String _formatMovingTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SyntrakSpacing.xs / 2),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapThumbnail(List<Location> locations, Color routeColor) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(color: SyntrakColors.surfaceVariant),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SyntrakColors.primary.withOpacity(0.1),
                  SyntrakColors.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.map,
                size: 60,
                color: SyntrakColors.textTertiary.withOpacity(0.3),
              ),
            ),
          ),
          if (locations.length > 1)
            Positioned.fill(
              child: CustomPaint(
                painter: ActivityRoutePreviewPainter(
                  locations: locations,
                  color: routeColor,
                ),
              ),
            ),
          Positioned(
            bottom: SyntrakSpacing.sm,
            right: SyntrakSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.sm,
                vertical: SyntrakSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(SyntrakRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white),
                  const SizedBox(width: SyntrakSpacing.xs / 2),
                  Text(
                    'View on map',
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        _buildBadge(
          icon: Icons.emoji_events,
          label: 'Long',
          color: SyntrakColors.accent,
        ),
      );
    }
    if (activity.elevationGain > 1000) {
      badges.add(
        _buildBadge(
          icon: Icons.trending_up,
          label: 'Elevation',
          color: SyntrakColors.secondary,
        ),
      );
    }
    if (activity.distance > 5000 && activity.elevationGain > 500) {
      badges.add(
        _buildBadge(
          icon: Icons.star,
          label: 'PR',
          color: SyntrakColors.accent,
        ),
      );
    }
    return badges;
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
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
