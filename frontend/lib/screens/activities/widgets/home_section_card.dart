import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

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
                      borderRadius: BorderRadius.circular(SyntrakRadius.md),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: SyntrakTypography.labelLarge.copyWith(
                            color: SyntrakColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
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
