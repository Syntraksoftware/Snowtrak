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
      color: SnowtrakColors.surface,
      padding: const EdgeInsets.fromLTRB(
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: SnowtrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: SnowtrakColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search activities...',
            hintStyle: SnowtrakTypography.bodyMedium.copyWith(
              color: SnowtrakColors.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: SnowtrakColors.textTertiary,
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: SnowtrakColors.textSecondary,
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
