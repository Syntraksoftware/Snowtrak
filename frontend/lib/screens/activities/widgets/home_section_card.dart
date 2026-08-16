import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Compact section shell for the home feed — same DNA as profile cards, tighter rhythm.
class HomeSectionCard extends StatelessWidget {
  const HomeSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? SnowtrakColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
      child: Material(
        color: SnowtrakColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          side: const BorderSide(color: SnowtrakColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: SnowtrakSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: SnowtrakTypography.labelLarge.copyWith(
                            color: SnowtrakColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitle!,
                            style: SnowtrakTypography.bodySmall.copyWith(
                              color: SnowtrakColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
