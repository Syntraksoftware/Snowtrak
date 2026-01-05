import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:intl/intl.dart';

class ActivitiesTab extends StatefulWidget {
  final List<Activity> activities;
  
  const ActivitiesTab({
    super.key,
    required this.activities,
  });

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.downhill_skiing,
                size: 80,
                color: SyntrakColors.textTertiary,
              ),
              const SizedBox(height: SyntrakSpacing.lg),
              Text(
                'No activities yet',
                style: SyntrakTypography.headlineMedium.copyWith(
                  color: SyntrakColors.textSecondary,
                ),
              ),
              const SizedBox(height: SyntrakSpacing.sm),
              Text(
                'Start recording your first skiing activity!',
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh activities from backend
        await Future.delayed(const Duration(seconds: 1));
      },
      color: SyntrakColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(SyntrakSpacing.md),
        itemCount: widget.activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: SyntrakSpacing.md),
        itemBuilder: (context, index) {
          final activity = widget.activities[index];
          return _ActivityCard(activity: activity);
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final int kudosCount = 0; // TODO: Get from backend
  final bool isFirstActivity = false; // TODO: Determine from backend

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityColor = ActivityHelpers.getActivityColor(activity.type);
    final activityIcon = ActivityHelpers.getActivityIcon(activity.type);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(color: SyntrakColors.divider),
      ),
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
            // Header with activity name
            Padding(
              padding: const EdgeInsets.all(SyntrakSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(SyntrakSpacing.sm),
                    decoration: BoxDecoration(
                      color: activityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(SyntrakRadius.md),
                    ),
                    child: Icon(
                      activityIcon,
                      color: activityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name ?? activity.type.displayName,
                          style: SyntrakTypography.headlineSmall.copyWith(
                            color: SyntrakColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SyntrakSpacing.xs),
                        // Subtitle: Distance, Elev Gain, Time
                        Row(
                          children: [
                            _buildSubtitleItem(
                              Icons.straighten,
                              activity.formattedDistance,
                            ),
                            const SizedBox(width: SyntrakSpacing.md),
                            _buildSubtitleItem(
                              Icons.trending_up,
                              activity.formattedVerticalDrop,
                            ),
                            const SizedBox(width: SyntrakSpacing.md),
                            _buildSubtitleItem(
                              Icons.timer,
                              activity.formattedDuration,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(activity.startTime),
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Kudos bar (if first activity)
            if (isFirstActivity)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: SyntrakSpacing.md,
                  vertical: SyntrakSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: SyntrakColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: SyntrakColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Text(
                      'Kudos on your first activity!',
                      style: SyntrakTypography.bodySmall.copyWith(
                        color: SyntrakColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (isFirstActivity) const SizedBox(height: SyntrakSpacing.md),
            
            // Map preview
            if (activity.locations.isNotEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                  border: Border.all(color: SyntrakColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                  child: _buildMapPreview(activity),
                ),
              ),
            
            if (activity.locations.isNotEmpty)
              const SizedBox(height: SyntrakSpacing.md),
            
            // Action buttons: Like, Share, Comment
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.favorite_border,
                    label: 'Like',
                    count: kudosCount,
                    onTap: () {
                      // TODO: Implement like functionality
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {
                      // TODO: Implement share functionality
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    onTap: () {
                      // TODO: Implement comment functionality
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: SyntrakSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: SyntrakColors.textTertiary,
        ),
        const SizedBox(width: SyntrakSpacing.xs),
        Text(
          text,
          style: SyntrakTypography.bodySmall.copyWith(
            color: SyntrakColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(Activity activity) {
    if (activity.locations.isEmpty) {
      return Container(
        color: SyntrakColors.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.map,
            color: SyntrakColors.textTertiary,
            size: 40,
          ),
        ),
      );
    }

    // Calculate bounds for the map
    final lats = activity.locations.map((l) => l.latitude).toList();
    final lngs = activity.locations.map((l) => l.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Create polyline points
    final polylinePoints = activity.locations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toSet()
        .toList();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(centerLat, centerLng),
        zoom: 13,
      ),
      mapType: MapType.normal,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      polylines: {
        Polyline(
          polylineId: PolylineId('route_${activity.id}'),
          points: polylinePoints,
          color: ActivityHelpers.getActivityColor(activity.type),
          width: 4,
        ),
      },
      markers: {
        if (activity.locations.isNotEmpty)
          Marker(
            markerId: MarkerId('start_${activity.id}'),
            position: LatLng(
              activity.locations.first.latitude,
              activity.locations.first.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        if (activity.locations.length > 1)
          Marker(
            markerId: MarkerId('end_${activity.id}'),
            position: LatLng(
              activity.locations.last.latitude,
              activity.locations.last.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    int? count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SyntrakRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: SyntrakColors.textSecondary,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: SyntrakSpacing.xs),
              Text(
                count.toString(),
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(width: SyntrakSpacing.xs),
            Text(
              label,
              style: SyntrakTypography.labelMedium.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

