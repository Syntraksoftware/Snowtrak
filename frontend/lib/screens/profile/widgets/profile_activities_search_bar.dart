import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

class ProfileActivitiesSearchBar extends StatelessWidget {
  const ProfileActivitiesSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search activities...',
            hintStyle: SnowtrakTypography.bodyMedium.copyWith(
              color: context.colors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: context.colors.textTertiary,
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.colors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SnowtrakSpacing.md,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
