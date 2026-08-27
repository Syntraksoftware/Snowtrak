import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

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
      padding: const EdgeInsets.symmetric(vertical: SnowtrakSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SnowtrakColors.textTertiary),
          const SizedBox(width: SnowtrakSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: SnowtrakColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: SnowtrakTypography.labelLarge.copyWith(
              color: SnowtrakColors.textPrimary,
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
        padding: const EdgeInsets.all(SnowtrakSpacing.sm),
        decoration: BoxDecoration(
          color: SnowtrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: SnowtrakSpacing.xs),
            Text(
              label,
              style: SnowtrakTypography.labelSmall.copyWith(
                color: SnowtrakColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: SnowtrakTypography.metricMedium.copyWith(
                  color: SnowtrakColors.textPrimary,
                  fontSize: 18,
                ),
                children: [
                  TextSpan(text: value),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: SnowtrakTypography.labelMedium.copyWith(
                        color: SnowtrakColors.textSecondary,
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
        const SizedBox(width: SnowtrakSpacing.sm),
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
        horizontal: SnowtrakSpacing.sm,
        vertical: SnowtrakSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected
            ? SnowtrakColors.primary.withValues(alpha: 0.12)
            : SnowtrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.round),
        border: Border.all(
          color: selected ? SnowtrakColors.primary : SnowtrakColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: selected ? SnowtrakColors.primary : SnowtrakColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: SnowtrakTypography.labelMedium.copyWith(
              color: selected ? SnowtrakColors.primary : SnowtrakColors.textSecondary,
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
        color: SnowtrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        border: Border.all(color: SnowtrakColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: SnowtrakColors.textTertiary),
          const SizedBox(height: SnowtrakSpacing.xs),
          Text(
            label,
            style: SnowtrakTypography.bodySmall.copyWith(
              color: SnowtrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
