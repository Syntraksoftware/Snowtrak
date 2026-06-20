import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

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
      color: SyntrakColors.surfaceVariant,
      borderRadius: BorderRadius.circular(SyntrakRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyntrakRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SyntrakSpacing.sm,
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
                      style: SyntrakTypography.labelLarge.copyWith(
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
              Icon(icon, size: 18, color: SnowtrakAuthTheme.brand),
            ],
          ),
        ),
      ),
    );
  }
}
