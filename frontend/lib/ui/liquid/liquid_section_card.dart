import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Full-width section card with icon header for profile and settings layouts.
class LiquidSectionCard extends StatelessWidget {
  const LiquidSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? context.colors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
      child: Material(
        color: context.colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          side: BorderSide(color: context.colors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SnowtrakSpacing.md,
                  SnowtrakSpacing.md,
                  SnowtrakSpacing.md,
                  SnowtrakSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                      ),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: SnowtrakSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: SnowtrakTypography.headlineSmall.copyWith(
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: SnowtrakTypography.bodySmall.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: context.colors.textTertiary,
                        size: 20,
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
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
