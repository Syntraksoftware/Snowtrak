import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Fixed, full-width underline tabs — the strip under a page title
/// ("Threads / Leaderboards" in the design file).
class StTabBar extends StatelessWidget implements PreferredSizeWidget {
  const StTabBar({super.key, required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SnowtrakColors.surface,
      child: TabBar(
        controller: controller,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        indicatorColor: SnowtrakColors.ink,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: SnowtrakColors.border,
        dividerHeight: 1,
        labelColor: SnowtrakColors.textPrimary,
        unselectedLabelColor: SnowtrakColors.textQuaternary,
        labelStyle: SnowtrakTypography.labelLarge,
        unselectedLabelStyle: SnowtrakTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: labels
            .map(
              (label) => Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
