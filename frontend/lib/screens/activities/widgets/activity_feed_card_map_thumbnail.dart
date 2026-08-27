import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/location.dart';
import 'package:snowtrak/screens/activities/widgets/activity_route_preview_painter.dart';

class ActivityFeedCardMapThumbnail extends StatelessWidget {
  const ActivityFeedCardMapThumbnail({
    super.key,
    required this.locations,
    required this.routeColor,
    this.imageUrl,
  });

  final List<Location> locations;
  final Color routeColor;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Container(
        height: 200,
        color: SnowtrakColors.surfaceVariant,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                color: SnowtrakColors.textTertiary,
                size: 40,
              ),
              const SizedBox(height: SnowtrakSpacing.sm),
              Text(
                'No route data',
                style: SnowtrakTypography.bodySmall.copyWith(
                  color: SnowtrakColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If a server-rendered thumbnail is available, use it (fast, no GL).
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: SnowtrakColors.surfaceVariant,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: SnowtrakColors.surfaceVariant,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // fallback to the vector preview painter if the image fails
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SnowtrakColors.primary.withOpacity(0.1),
                          SnowtrakColors.secondary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: locations.length > 1
                        ? CustomPaint(
                            painter: ActivityRoutePreviewPainter(
                              locations: locations,
                              color: routeColor,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            Positioned(
              bottom: SnowtrakSpacing.sm,
              right: SnowtrakSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SnowtrakSpacing.sm,
                  vertical: SnowtrakSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white),
                    const SizedBox(width: SnowtrakSpacing.xs / 2),
                    Text(
                      'View on map',
                      style: SnowtrakTypography.labelSmall.copyWith(
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

    // Fallback: render lightweight vector preview locally
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(color: SnowtrakColors.surfaceVariant),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SnowtrakColors.primary.withOpacity(0.1),
                  SnowtrakColors.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.map,
                size: 60,
                color: SnowtrakColors.textTertiary.withOpacity(0.3),
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
            bottom: SnowtrakSpacing.sm,
            right: SnowtrakSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SnowtrakSpacing.sm,
                vertical: SnowtrakSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white),
                  const SizedBox(width: SnowtrakSpacing.xs / 2),
                  Text(
                    'View on map',
                    style: SnowtrakTypography.labelSmall.copyWith(
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
