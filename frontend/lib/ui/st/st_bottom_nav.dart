import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/st/st_icon.dart';

/// A tab in [StBottomNav]. The record tab draws the ink disc instead of an icon.
class StNavItem {
  const StNavItem({required this.icon, required this.label});

  final String icon;
  final String label;
}

/// Home / Map / Record / Community / Profile — an 84pt bar with the record
/// action as a 58pt ink disc sitting inline, per `07 · Screens — Home`.
class StBottomNav extends StatelessWidget {
  const StBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.recordIndex,
  });

  final List<StNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int recordIndex;

  static const double barHeight = 84;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: barHeight + bottomInset,
      padding: EdgeInsets.only(top: 6, bottom: bottomInset),
      decoration: const BoxDecoration(
        color: SnowtrakColors.surface,
        border: Border(top: BorderSide(color: SnowtrakColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              flex: i == recordIndex ? 4 : 3,
              child: i == recordIndex
                  ? _RecordTab(
                      label: items[i].label,
                      onTap: () => onTap(i),
                    )
                  : _Tab(
                      item: items[i],
                      active: currentIndex == i,
                      onTap: () => onTap(i),
                    ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final StNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? SnowtrakColors.ink : SnowtrakColors.textTertiary;
    return InkResponse(
      onTap: onTap,
      radius: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          StIcon(item.icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SnowtrakTypography.labelSmall.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTab extends StatelessWidget {
  const _RecordTab({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: SnowtrakColors.ink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: SnowtrakColors.textOnPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.xs),
          Text(
            label,
            style: SnowtrakTypography.labelSmall.copyWith(
              color: SnowtrakColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
