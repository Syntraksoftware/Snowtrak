import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Uppercase eyebrow that opens every section — "YOUR STATISTICS", with an
/// optional "See all →" on the right. 20pt gutters, per `07 · Screens — Home`.
class StSectionHeader extends StatelessWidget {
  const StSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
    this.padding =
        const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.lmd),
  });

  final String title;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget? end = trailing;
    if (end == null && actionLabel != null) {
      end = GestureDetector(
        onTap: onAction,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              actionLabel!,
              style: SnowtrakTypography.labelMedium.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: SnowtrakSpacing.xs),
            Icon(
              Icons.arrow_forward,
              size: 13,
              color: context.colors.primary,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: SnowtrakTypography.eyebrow.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
          if (end != null) end,
        ],
      ),
    );
  }
}
