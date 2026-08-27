import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/home/home_stats.dart';
import 'package:snowtrak/ui/st/st.dart';

/// The lifetime numbers, in the same 4-up strip the design uses on Home.
///
/// [activities] is null when the totals are not knowable — someone else's
/// profile, whose activities the app cannot read. That renders as `—` rather
/// than as zeroes, because "0 sessions" claims they have never skied and an
/// em dash only claims we do not know.
class ProfileTotals extends StatelessWidget {
  const ProfileTotals({super.key, required this.activities});

  final List<Activity>? activities;

  @override
  Widget build(BuildContext context) {
    final activities = this.activities;

    String value(String Function(List<Activity>) format) =>
        activities == null ? '—' : format(activities);

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
                value: value((a) => '${a.length}'),
                label: 'Sessions',
              ),
            ),
            Expanded(
              child: StStatTile(
                value: value(
                  (a) => Imperial.vertical(
                    a.fold(0.0, (sum, x) => sum + x.elevationGain),
                  ),
                ),
                label: 'Vert ft',
              ),
            ),
            Expanded(
              child: StStatTile(
                value: value(
                  (a) => Imperial.distance(
                    a.fold(0.0, (sum, x) => sum + x.distance),
                  ),
                ),
                label: 'Distance',
              ),
            ),
            Expanded(
              child: StStatTile(
                value: value(
                  (a) => Imperial.duration(
                    a.fold(0, (sum, x) => sum + x.duration),
                  ),
                ),
                label: 'Time',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
