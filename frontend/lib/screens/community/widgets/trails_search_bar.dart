import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

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
      color: SyntrakColors.surface,
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSearchFocused
              ? SyntrakColors.surface
              : SyntrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(SyntrakRadius.round),
          border: Border.all(
            color: isSearchFocused ? SyntrakColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSearchFocused
              ? [
                  BoxShadow(
                    color: SyntrakColors.primary.withAlpha(30),
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
          style: SyntrakTypography.bodyMedium.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search trails, resorts...',
            hintStyle: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isSearchFocused
                  ? SyntrakColors.primary
                  : SyntrakColors.textTertiary,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: SyntrakColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SyntrakSpacing.md,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
