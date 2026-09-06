import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/user_stats.dart';
import 'package:snowtrak/screens/profile/widgets/profile_totals.dart';

/// `ProfileTotals` must show `ActivityProvider.stats.allTime*` -- the
/// lifetime numbers -- not a fold over whatever page of activities happens
/// to be in memory (`ActivityProvider._pageSize` is 20; issue #70).
///
/// Every fixture below carries activities and stats that disagree, so a
/// widget that (even accidentally) sums activities instead of reading
/// `stats` fails these assertions instead of coincidentally passing.
void main() {
  UserStats statsFixture({
    int allTimeSessionCount = 41,
    double allTimeDistanceKm = 12.5,
    int allTimeTimeMin = 130,
    double allTimeElevGain = 900.0,
  }) {
    return UserStats(
      weekStart: DateTime(2026, 8, 31),
      weeklyDistanceKm: 0,
      weeklyTimeMin: 0,
      weeklyElevGain: 0,
      weeklySessionCount: 0,
      lastWeekSessionCount: 0,
      yearlyDistanceKm: 0,
      yearlyTimeMin: 0,
      yearlyElevGain: 0,
      yearlySessionCount: 0,
      allTimeDistanceKm: allTimeDistanceKm,
      allTimeTimeMin: allTimeTimeMin,
      allTimeElevGain: allTimeElevGain,
      allTimeSessionCount: allTimeSessionCount,
      activityDays: const {},
      bestEfforts: const [],
      currentStreak: 0,
      longestStreak: 0,
    );
  }

  Future<void> pump(WidgetTester tester, UserStats? stats) {
    return tester.pumpWidget(
      MaterialApp(
        theme: SnowtrakTheme.lightTheme,
        home: Scaffold(body: ProfileTotals(stats: stats)),
      ),
    );
  }

  testWidgets('renders lifetime sessions from stats, not a page count',
      (tester) async {
    // 41 lifetime sessions is well past the 20-activity page the old widget
    // folded over -- a page-based reading could never show this number.
    await pump(tester, statsFixture(allTimeSessionCount: 41));

    expect(find.text('41'), findsOneWidget);
  });

  testWidgets('converts allTimeDistanceKm (km) to the imperial display (miles)',
      (tester) async {
    // 12.5 km == 12_500 m == 7.767... mi. A units bug that treats km as
    // metres would instead show "12.5 mi" -- both numbers below are
    // asserted so that mistake cannot pass by coincidence.
    await pump(tester, statsFixture(allTimeDistanceKm: 12.5));

    expect(find.text('7.8 mi'), findsOneWidget);
    expect(find.text('12.5 mi'), findsNothing);
  });

  testWidgets('converts allTimeTimeMin (minutes) to the imperial display (h/m)',
      (tester) async {
    // 130 min == 2h 10m == 7800 s. A units bug that treats minutes as
    // seconds would instead show "2m".
    await pump(tester, statsFixture(allTimeTimeMin: 130));

    expect(find.text('2h 10m'), findsOneWidget);
    expect(find.text('2m'), findsNothing);
  });

  testWidgets('renders allTimeElevGain (already metres) unconverted',
      (tester) async {
    await pump(tester, statsFixture(allTimeElevGain: 900.0));

    expect(find.text('2,953 ft'), findsOneWidget);
  });

  testWidgets('renders em dash for null stats -- unknown, not zero',
      (tester) async {
    await pump(tester, null);

    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('0'), findsNothing);
  });
}
