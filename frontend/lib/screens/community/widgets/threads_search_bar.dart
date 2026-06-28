import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Pinned search field for the threads tab (focus ring + clear).
class ThreadsSearchBar extends StatelessWidget {
  const ThreadsSearchBar({
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
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SyntrakColors.background,
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: SyntrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(SyntrakRadius.round),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onQueryChanged,
          style: SyntrakTypography.bodyMedium.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search posts, users...',
            hintStyle: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: SyntrakColors.textTertiary,
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
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
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
