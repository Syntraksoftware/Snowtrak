import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/user_stats.dart';
import 'package:snowtrak/screens/home/home_stats.dart';
import 'package:snowtrak/ui/st/st.dart';

/// The lifetime numbers, in the same 4-up strip the design uses on Home.
///
/// Reads `stats.allTime*` rather than folding over whatever page of
/// activities happens to be loaded -- `ActivityProvider` only ever holds one
/// page, so a fold silently stopped growing past the page size (#70).
///
/// [stats] is null when the totals are not knowable -- someone else's
/// profile, whose stats the app cannot read, or the signed-in user's own
/// stats before the first fetch lands. That renders as `—` rather than as
/// zeroes, because "0 sessions" claims they have never skied and an em dash
/// only claims we do not know. A user with genuinely zero activities gets a
/// non-null [stats] with zero counts, and reads as zeros.
class ProfileTotals extends StatelessWidget {
  const ProfileTotals({super.key, required this.stats});

  final UserStats? stats;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;

    String value(String Function(UserStats) format) =>
        stats == null ? '—' : format(stats);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SnowtrakSpacing.md,
        SnowtrakSpacing.smd,
        SnowtrakSpacing.md,
        0,
      ),
      child: StCard(
        child: Row(
          children: [
            Expanded(
              child: StStatTile(
                value: value((s) => '${s.allTimeSessionCount}'),
                label: 'Sessions',
              ),
            ),
            Expanded(
              child: StStatTile(
                // Already metres -- no conversion, unlike the two below.
                value: value((s) => Imperial.vertical(s.allTimeElevGain)),
                label: 'Vert ft',
              ),
            ),
            Expanded(
              child: StStatTile(
                // allTimeDistanceKm is kilometres; Imperial.distance takes
                // metres.
                value: value((s) => Imperial.distance(s.allTimeDistanceKm * 1000)),
                label: 'Distance',
              ),
            ),
            Expanded(
              child: StStatTile(
                // allTimeTimeMin is minutes; Imperial.duration takes seconds.
                value: value((s) => Imperial.duration(s.allTimeTimeMin * 60)),
                label: 'Time',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
