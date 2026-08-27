import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// The header every tab opens with — 74pt tall, 20pt gutters, title (optionally
/// under a small greeting) and up to two 40pt round actions.
/// Matches `07 · Screens — Home` → `Device/HomeFeed` → `Header`.
class StPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const StPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final String? eyebrow;

  /// Optional widget before the title — a back button on a pushed screen.
  final Widget? leading;

  final List<Widget> actions;

  /// Optional row pinned under the title — tab strips, search fields.
  final Widget? bottom;

  static const double _height = 74;

  /// Lets the header be passed straight to `Scaffold.appBar`.
  @override
  Size get preferredSize {
    final extra = bottom is PreferredSizeWidget
        ? (bottom! as PreferredSizeWidget).preferredSize.height
        : 0.0;
    return Size.fromHeight(_height + extra);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SnowtrakColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SnowtrakSpacing.lmd,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: SnowtrakSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!,
                            style: SnowtrakTypography.bodyMedium.copyWith(
                              color: SnowtrakColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: SnowtrakSpacing.xxs),
                        ],
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SnowtrakTypography.headlineLarge.copyWith(
                            color: SnowtrakColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: SnowtrakSpacing.sm),
                    action,
                  ],
                ],
              ),
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
