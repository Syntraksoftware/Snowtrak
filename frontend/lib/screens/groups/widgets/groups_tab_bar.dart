import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Fixed, full-width underline tabs — Threads / Instagram style.
class GroupsTabBar extends StatelessWidget implements PreferredSizeWidget {
  const GroupsTabBar({super.key, required this.controller});

  final TabController controller;

  static const _labels = ['Activity', 'Challenges', 'Clubs', 'Trails'];

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: false,
      tabAlignment: TabAlignment.fill,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      indicatorColor: SyntrakColors.textPrimary,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: SyntrakColors.divider,
      dividerHeight: 0.5,
      labelColor: SyntrakColors.textPrimary,
      unselectedLabelColor: SyntrakColors.textTertiary,
      labelStyle: SyntrakTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: SyntrakTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: _labels
          .map(
            (label) => Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1),
              ),
            ),
          )
          .toList(),
    );
  }
}
