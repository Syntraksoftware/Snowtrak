import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/st/st_icon.dart';

/// 40px circular action in a page header (search, notifications, menu).
class StRoundButton extends StatelessWidget {
  const StRoundButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = false,
    this.tooltip,
  });

  final String icon;
  final VoidCallback? onTap;
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: SnowtrakColors.surfaceVariant,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StIcon(icon, size: 18, color: SnowtrakColors.ink),
              if (badge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: SnowtrakColors.ink,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: SnowtrakColors.surfaceVariant, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// The full-width ink CTA that closes a card — "Start Session Here".
class StInkButton extends StatelessWidget {
  const StInkButton({
    super.key,
    required this.label,
    this.onTap,
    this.leading,
    this.trailing,
    this.radius = 0,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SnowtrakColors.ink,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: SnowtrakSpacing.sm),
              ],
              Text(
                label,
                style: SnowtrakTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SnowtrakColors.textOnPrimary,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: SnowtrakSpacing.smd),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill toggle on a filled track — "This Week / This Month".
class StSegmented extends StatelessWidget {
  const StSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.segmentWidth = 90,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double segmentWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SnowtrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: segmentWidth,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selectedIndex
                      ? SnowtrakColors.ink
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(SnowtrakRadius.round),
                ),
                child: Text(
                  labels[i],
                  style: SnowtrakTypography.eyebrow.copyWith(
                    letterSpacing: 0,
                    color: i == selectedIndex
                        ? SnowtrakColors.textOnPrimary
                        : SnowtrakColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small neutral pill used as a secondary action inside cards — "View".
class StChipButton extends StatelessWidget {
  const StChipButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SnowtrakColors.surfaceVariant,
      borderRadius: BorderRadius.circular(SnowtrakRadius.round),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 62),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.smd),
          child: Text(
            label,
            style: SnowtrakTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: SnowtrakColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
