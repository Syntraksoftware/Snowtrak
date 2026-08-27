import 'package:flutter/material.dart';

/// Bottom-nav slots, in the order the design file lays them out
/// (`12 layout now` → BottomNav). Record is the centre FAB.
class HomeTab {
  static const int home = 0;
  static const int map = 1;
  static const int record = 2;
  static const int community = 3;
  static const int profile = 4;
}

/// Lets nested home tabs (e.g. Home feed) switch the bottom navigation index.
class HomeTabScope extends InheritedWidget {
  const HomeTabScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(int index) selectTab;

  static HomeTabScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<HomeTabScope>();
  }

  static void selectTabOrNull(BuildContext context, int index) {
    maybeOf(context)?.selectTab(index);
  }

  @override
  bool updateShouldNotify(HomeTabScope oldWidget) => false;
}
