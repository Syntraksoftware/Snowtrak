import 'package:flutter/material.dart';

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
