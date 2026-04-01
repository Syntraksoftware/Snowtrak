import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user.dart';

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
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(color: SyntrakColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: SyntrakColors.surfaceVariant,
                  child: user?.firstName != null
                      ? Text(
                          user!.firstName![0].toUpperCase(),
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 20,
                          color: SyntrakColors.textTertiary,
                        ),
                ),
                const SizedBox(width: SyntrakSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: SyntrakSpacing.xs / 2),
                      Text(
                        '${_formatDateTime(activity.startTime)} • Apple Watch SE',
                        style: SyntrakTypography.labelSmall.copyWith(
                          color: SyntrakColors.textTertiary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SyntrakSpacing.xs / 2),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: SyntrakColors.textTertiary,
                          ),
                          const SizedBox(width: SyntrakSpacing.xs / 2),
                          Expanded(
                            child: Text(
                              'Finland, Tampere',
                              style: SyntrakTypography.labelSmall.copyWith(
                                color: SyntrakColors.textTertiary,
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
              SyntrakSpacing.md,
              0,
              SyntrakSpacing.md,
              SyntrakSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name ?? activity.type.displayName,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _metric('Distance', activity.formattedDistance),
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Expanded(
                      child: _metric('Elev Gain', activity.formattedVerticalDrop),
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
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
                  const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                decoration: BoxDecoration(
                  color: SyntrakColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SyntrakColors.primary,
                            SyntrakColors.accent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: SyntrakTypography.labelLarge.copyWith(
                            color: SyntrakColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.md),
                    Expanded(
                      child: Text(
                        'Kudos on your first activity!',
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SyntrakColors.accent,
                        foregroundColor: SyntrakColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SyntrakSpacing.md,
                          vertical: SyntrakSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View',
                        style: SyntrakTypography.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
          ],
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SyntrakColors.surfaceVariant,
            ),
            child: ClipRRect(
              child: _mapPreview(),
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                  icon: hasKudos ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  count: kudosCount,
                  color: hasKudos
                      ? SyntrakColors.primary
                      : SyntrakColors.textSecondary,
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
          const SizedBox(height: SyntrakSpacing.md),
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
          style: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: SyntrakSpacing.xs / 2),
        Text(
          value,
          style: SyntrakTypography.bodyMedium.copyWith(
            color: SyntrakColors.textPrimary,
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
            color: SyntrakColors.surfaceVariant,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    color: SyntrakColors.textTertiary,
                    size: 40,
                  ),
                  const SizedBox(height: SyntrakSpacing.sm),
                  Text(
                    'Map preview',
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textTertiary,
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
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    int? count,
    Color? color,
    required VoidCallback onTap,
  }) {
    final buttonColor = color ?? SyntrakColors.textSecondary;
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
              color: buttonColor,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: SyntrakSpacing.xs),
              Text(
                count.toString(),
                style: SyntrakTypography.bodySmall.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: SyntrakSpacing.xs),
            Text(
              label,
              style: SyntrakTypography.labelMedium.copyWith(
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
