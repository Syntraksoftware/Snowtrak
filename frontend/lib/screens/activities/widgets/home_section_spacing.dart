import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Consistent vertical rhythm between home feed section cards.
class HomeSectionSpacing extends StatelessWidget {
  const HomeSectionSpacing({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SyntrakSpacing.sm),
      child: child,
    );
  }
}
