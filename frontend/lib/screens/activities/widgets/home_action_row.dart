import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Compact tappable row for home section previews.
class HomeActionRow extends StatelessWidget {
  const HomeActionRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.chevron_right,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(SnowtrakRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SnowtrakSpacing.sm,
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SnowtrakTypography.labelLarge.copyWith(
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
              Icon(icon, size: 18, color: context.colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
