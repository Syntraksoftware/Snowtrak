import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/st/st_icon.dart';

/// Centred metric with an optional icon above — the conditions strip.
class StStatTile extends StatelessWidget {
  const StStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Icon tiles sit in a fixed 78pt strip; text-only tiles set their own height.
      padding: EdgeInsets.symmetric(
        vertical: icon == null ? 15 : 8,
        horizontal: SnowtrakSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            StIcon(icon!, size: 18, color: context.colors.textSecondary),
            const SizedBox(height: 5),
          ],
          Text(
            value,
            style: SnowtrakTypography.metricSmall.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SnowtrakTypography.caption.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Left-aligned metric used in the 2-up statistics grid.
class StStatCell extends StatelessWidget {
  const StStatCell({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SnowtrakTypography.metricMedium.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.xs),
          Text(
            label,
            style: SnowtrakTypography.labelMedium.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 2-up grid of [StStatCell]s separated by hairlines. Rows come in pairs.
class StStatGrid extends StatelessWidget {
  const StStatGrid({super.key, required this.cells});

  final List<StStatCell> cells;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cells[i]),
              VerticalDivider(width: 1, color: context.colors.border),
              Expanded(
                child: i + 1 < cells.length
                    ? cells[i + 1]
                    : ColoredBox(color: context.colors.surface),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < cells.length) {
        rows.add(Divider(height: 1, color: context.colors.border));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
