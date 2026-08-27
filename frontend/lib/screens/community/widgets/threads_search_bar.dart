import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

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
      color: context.colors.background,
      padding: const EdgeInsets.fromLTRB(
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(SnowtrakRadius.round),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onQueryChanged,
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search posts, users...',
            hintStyle: SnowtrakTypography.bodyMedium.copyWith(
              color: context.colors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: context.colors.textTertiary,
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
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
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
