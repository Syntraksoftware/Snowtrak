import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/user.dart';

/// Strava-style activity row for the profile Activities list.
class ProfileActivityListCard extends StatelessWidget {
  const ProfileActivityListCard({
    super.key,
    required this.activity,
    required this.user,
    required this.isFirstActivity,
    required this.hasKudos,
    required this.kudosCount,
    required this.onKudosToggle,
    required this.onShare,
    required this.onComment,
  });

  final Activity activity;
  final User? user;
  final bool isFirstActivity;
  final bool hasKudos;
  final int kudosCount;
  final VoidCallback onKudosToggle;
  final VoidCallback onShare;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        side: const BorderSide(color: SnowtrakColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(SnowtrakSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: SnowtrakColors.surfaceVariant,
                  child: user?.firstName != null
                      ? Text(
                          user!.firstName![0].toUpperCase(),
                          style: SnowtrakTypography.bodyMedium.copyWith(
                            color: SnowtrakColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 20,
                          color: SnowtrakColors.textTertiary,
                        ),
                ),
                const SizedBox(width: SnowtrakSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: SnowtrakTypography.bodyMedium.copyWith(
                          color: SnowtrakColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: SnowtrakSpacing.xs / 2),
                      Text(
                        '${_formatDateTime(activity.startTime)} • Apple Watch SE',
                        style: SnowtrakTypography.labelSmall.copyWith(
                          color: SnowtrakColors.textTertiary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SnowtrakSpacing.xs / 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: SnowtrakColors.textTertiary,
                          ),
                          const SizedBox(width: SnowtrakSpacing.xs / 2),
                          Expanded(
                            child: Text(
                              'Finland, Tampere',
                              style: SnowtrakTypography.labelSmall.copyWith(
                                color: SnowtrakColors.textTertiary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
              SnowtrakSpacing.md,
              0,
              SnowtrakSpacing.md,
              SnowtrakSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name ?? activity.type.displayName,
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: SnowtrakColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _metric('Distance', activity.formattedDistance),
                    ),
                    const SizedBox(width: SnowtrakSpacing.sm),
                    Expanded(
                      child: _metric('Elev Gain', activity.formattedVerticalDrop),
                    ),
                    const SizedBox(width: SnowtrakSpacing.sm),
                    Expanded(
                      child: _metric('Time', activity.formattedDuration),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isFirstActivity) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(SnowtrakSpacing.md),
                decoration: BoxDecoration(
                  color: SnowtrakColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SnowtrakColors.primary,
                            SnowtrakColors.accent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: SnowtrakTypography.labelLarge.copyWith(
                            color: SnowtrakColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: SnowtrakSpacing.md),
                    Expanded(
                      child: Text(
                        'Kudos on your first activity!',
                        style: SnowtrakTypography.bodyMedium.copyWith(
                          color: SnowtrakColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SnowtrakColors.accent,
                        foregroundColor: SnowtrakColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SnowtrakSpacing.md,
                          vertical: SnowtrakSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View',
                        style: SnowtrakTypography.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SnowtrakSpacing.md),
          ],
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: SnowtrakColors.surfaceVariant,
            ),
            child: ClipRRect(
              child: _mapPreview(),
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                  icon: hasKudos ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  count: kudosCount,
                  color: hasKudos
                      ? SnowtrakColors.primary
                      : SnowtrakColors.textSecondary,
                  onTap: onKudosToggle,
                ),
                _actionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: onComment,
                ),
                _actionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: onShare,
                ),
              ],
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: SnowtrakTypography.labelSmall.copyWith(
            color: SnowtrakColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.xs / 2),
        Text(
          value,
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: SnowtrakColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _mapPreview() {
    try {
      return Image.asset(
        'assets/images/activities_demo_1.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: SnowtrakColors.surfaceVariant,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map,
                    color: SnowtrakColors.textTertiary,
                    size: 40,
                  ),
                  const SizedBox(height: SnowtrakSpacing.sm),
                  Text(
                    'Map preview',
                    style: SnowtrakTypography.bodySmall.copyWith(
                      color: SnowtrakColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: SnowtrakColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.map,
            color: SnowtrakColors.textTertiary,
            size: 40,
          ),
        ),
      );
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    int? count,
    Color? color,
    required VoidCallback onTap,
  }) {
    final buttonColor = color ?? SnowtrakColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnowtrakRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SnowtrakSpacing.md,
          vertical: SnowtrakSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: buttonColor,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: SnowtrakSpacing.xs),
              Text(
                count.toString(),
                style: SnowtrakTypography.bodySmall.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: SnowtrakSpacing.xs),
            Text(
              label,
              style: SnowtrakTypography.labelMedium.copyWith(
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final dateFormat = DateFormat('MMMM d, yyyy \'at\' h:mm a');
    return dateFormat.format(date);
  }
}
