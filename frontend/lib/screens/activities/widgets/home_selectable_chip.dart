import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

class HomeSelectableChip extends StatelessWidget {
  const HomeSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final accent = SnowtrakAuthTheme.brand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyntrakRadius.round),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : SyntrakColors.surfaceVariant,
            borderRadius: BorderRadius.circular(SyntrakRadius.round),
            border: Border.all(
              color: selected ? accent : SyntrakColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : SyntrakSpacing.sm,
            vertical: dense ? 6 : SyntrakSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: dense ? 14 : 16,
                  color: selected ? accent : SyntrakColors.textSecondary,
                ),
                SizedBox(width: dense ? 4 : 6),
              ],
              Text(
                label,
                style: SyntrakTypography.labelMedium.copyWith(
                  color: selected ? accent : SyntrakColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
