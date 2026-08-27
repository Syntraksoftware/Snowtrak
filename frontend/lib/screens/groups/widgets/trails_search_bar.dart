import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

class TrailsSearchBar extends StatelessWidget {
  const TrailsSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSearchFocused,
    required this.onQueryChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearchFocused;
  final VoidCallback onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SnowtrakColors.background,
      padding: const EdgeInsets.fromLTRB(
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSearchFocused
              ? SnowtrakColors.surface
              : SnowtrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(SnowtrakRadius.round),
          border: Border.all(
            color: isSearchFocused ? SnowtrakColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSearchFocused
              ? [
                  BoxShadow(
                    color: SnowtrakColors.primary.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) => onQueryChanged(),
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: SnowtrakColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search trails, resorts...',
            hintStyle: SnowtrakTypography.bodyMedium.copyWith(
              color: SnowtrakColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isSearchFocused
                  ? SnowtrakColors.primary
                  : SnowtrakColors.textTertiary,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
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
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
