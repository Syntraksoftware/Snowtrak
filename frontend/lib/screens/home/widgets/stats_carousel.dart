import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/home/home_stats.dart';
import 'package:snowtrak/ui/st/st.dart';

/// "Your statistics" — a period summary followed by the sessions that made it.
/// Built to `07 · Screens — Home` → `StatsCard`.
class StatsCarousel extends StatefulWidget {
  const StatsCarousel({
    super.key,
    required this.activities,
    this.onOpenActivity,
  });

  final List<Activity> activities;
  final void Function(Activity activity)? onOpenActivity;

  @override
  State<StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<StatsCarousel> {
  final PageController _pages = PageController();
  StatsPeriod _period = StatsPeriod.week;
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = PeriodStats.from(widget.activities, _period);
    final recent = widget.activities.take(4).toList();
    final cards = <Widget>[
      _SummaryCard(stats: stats),
      for (final activity in recent)
        _SessionCard(
          activity: activity,
          onTap: () => widget.onOpenActivity?.call(activity),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StSectionHeader(
          title: 'Your statistics',
          trailing: StSegmented(
            labels: const ['This Week', 'This Month'],
            selectedIndex: _period.index,
            onChanged: (index) => setState(
              () => _period = StatsPeriod.values[index],
            ),
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.smd),
        SizedBox(
          height: 296,
          child: PageView.builder(
            controller: _pages,
            itemCount: cards.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
              child: cards[index],
            ),
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.sm),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: SnowtrakSpacing.xs),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: i == _page ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? context.colors.primary
                        : SnowtrakColors.neutral300,
                    borderRadius: BorderRadius.circular(SnowtrakRadius.round),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final range = '${DateFormat.MMMd().format(stats.start)} – '
        '${DateFormat.MMMd().format(stats.end)}';

    return StCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stats.period == StatsPeriod.week
                            ? 'This Week'
                            : 'This Month',
                        style: SnowtrakTypography.headlineSmall.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        range,
                        style: SnowtrakTypography.labelMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.sessions}',
                        style: SnowtrakTypography.headlineSmall.copyWith(
                          fontSize: 16,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Sessions',
                        style: SnowtrakTypography.caption.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const StHairline(),
          StStatGrid(
            cells: [
              StStatCell(value: '${stats.runs}', label: 'Total Runs'),
              StStatCell(
                value: Imperial.vertical(stats.verticalMetres),
                label: 'Vertical',
              ),
              StStatCell(
                value: Imperial.distance(stats.distanceMetres),
                label: 'Distance',
              ),
              StStatCell(
                value: Imperial.duration(stats.durationSeconds),
                label: 'Duration',
              ),
              StStatCell(
                value: Imperial.speed(stats.topSpeedMph),
                label: 'Top Speed',
              ),
              StStatCell(
                value: Imperial.speed(stats.avgSpeedMph),
                label: 'Avg Speed',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.activity, this.onTap});

  final Activity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = activity.name ?? 'Session';
    final when = DateFormat.MMMd().add_jm().format(activity.startTime);

    return StCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SnowtrakTypography.headlineSmall.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        when,
                        style: SnowtrakTypography.labelMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                StChipButton(label: 'View', onTap: onTap),
              ],
            ),
          ),
          const StHairline(),
          StStatGrid(
            cells: [
              StStatCell(
                value: Imperial.vertical(activity.elevationGain),
                label: 'Vertical',
              ),
              StStatCell(
                value: Imperial.distance(activity.distance),
                label: 'Distance',
              ),
              StStatCell(
                value: Imperial.duration(activity.duration),
                label: 'Duration',
              ),
              StStatCell(
                value: Imperial.speed(Imperial.mphFromPace(activity.maxPace)),
                label: 'Top Speed',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
