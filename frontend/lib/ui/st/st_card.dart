import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// The one card in the system: white, hairline border, 16px radius, no shadow.
class StCard extends StatelessWidget {
  const StCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.radius = SnowtrakRadius.lg,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Defaults to `context.colors.surface`; a constructor default cannot
  /// read the theme, so it is resolved in [build].
  final Color? color;
  final double radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: body,
      ),
    );
  }
}

/// Full-bleed hairline used inside cards to separate rows/columns.
class StHairline extends StatelessWidget {
  const StHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: context.colors.border),
      ),
    );
  }
}
