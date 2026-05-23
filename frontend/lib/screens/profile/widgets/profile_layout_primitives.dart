import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

/// Compact label + value row used in profile section placeholders.
class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SyntrakColors.textTertiary),
          const SizedBox(width: SyntrakSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: SyntrakTypography.labelLarge.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal stat tile for performance summaries.
class ProfileMetricTile extends StatelessWidget {
  const ProfileMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? SnowtrakAuthTheme.brand;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(SyntrakSpacing.sm),
        decoration: BoxDecoration(
          color: SyntrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(SyntrakRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: SyntrakSpacing.xs),
            Text(
              label,
              style: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: SyntrakTypography.metricMedium.copyWith(
                  color: SyntrakColors.textPrimary,
                  fontSize: 18,
                ),
                children: [
                  TextSpan(text: value),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: SyntrakTypography.labelMedium.copyWith(
                        color: SyntrakColors.textSecondary,
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

/// Two equal-width metric tiles with consistent spacing.
class ProfileMetricRow extends StatelessWidget {
  const ProfileMetricRow({
    super.key,
    required this.left,
    required this.right,
  });

  final ProfileMetricTile left;
  final ProfileMetricTile right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        left,
        const SizedBox(width: SyntrakSpacing.sm),
        right,
      ],
    );
  }
}

/// Pill chips for sports, filters, and club badges.
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.sm,
        vertical: SyntrakSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected
            ? SyntrakColors.primary.withValues(alpha: 0.12)
            : SyntrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SyntrakRadius.round),
        border: Border.all(
          color: selected ? SyntrakColors.primary : SyntrakColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: selected ? SyntrakColors.primary : SyntrakColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: SyntrakTypography.labelMedium.copyWith(
              color: selected ? SyntrakColors.primary : SyntrakColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder block for charts and maps not yet implemented.
class ProfilePlaceholderBlock extends StatelessWidget {
  const ProfilePlaceholderBlock({
    super.key,
    required this.icon,
    required this.label,
    this.height = 96,
  });

  final IconData icon;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SyntrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SyntrakRadius.md),
        border: Border.all(color: SyntrakColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: SyntrakColors.textTertiary),
          const SizedBox(height: SyntrakSpacing.xs),
          Text(
            label,
            style: SyntrakTypography.bodySmall.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Toggle row for privacy settings layout previews.
class ProfileToggleRow extends StatelessWidget {
  const ProfileToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SyntrakColors.textSecondary),
          const SizedBox(width: SyntrakSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SyntrakTypography.labelLarge.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: null,
            activeThumbColor: SnowtrakAuthTheme.brand,
          ),
        ],
      ),
    );
  }
}
