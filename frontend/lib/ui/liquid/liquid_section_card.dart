import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

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
    final accent = iconColor ?? SyntrakColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      child: Material(
        color: SyntrakColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          side: const BorderSide(color: SyntrakColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SyntrakSpacing.md,
                  SyntrakSpacing.md,
                  SyntrakSpacing.md,
                  SyntrakSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(SyntrakRadius.md),
                      ),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: SyntrakTypography.headlineSmall.copyWith(
                              color: SyntrakColors.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: SyntrakTypography.bodySmall.copyWith(
                                color: SyntrakColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: SyntrakColors.textTertiary,
                        size: 20,
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
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
