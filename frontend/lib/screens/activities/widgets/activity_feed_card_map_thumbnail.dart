import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/screens/activities/widgets/activity_route_preview_painter.dart';

class ActivityFeedCardMapThumbnail extends StatelessWidget {
  const ActivityFeedCardMapThumbnail({
    super.key,
    required this.locations,
    required this.routeColor,
  });

  final List<Location> locations;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Container(
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
      );
    }

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
}
