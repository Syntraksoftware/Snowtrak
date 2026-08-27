import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/profile/widgets/profile_home_content.dart';
import 'package:snowtrak/screens/profile/widgets/profile_totals.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Someone else's profile renders from no data at all: no activities, no
/// stats, no `profiles` row. Both pieces below have been laid out inside
/// fixed-height boxes that clipped their own contents, so this pumps them at
/// a phone width and fails on any overflow.
void main() {
  testWidgets('other-user profile sections lay out without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: SnowtrakTheme.lightTheme,
        home: Scaffold(
          appBar: const StPageHeader(
            title: 'Cache Tester',
            eyebrow: '@cachetester',
            leading: BackButton(),
          ),
          body: ListView(
            children: const [
              ProfileTotals(activities: null),
              ProfileHomeContent(isOwnProfile: false),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Privacy toggles are the viewer's own settings; they must not appear on
    // somebody else's page.
    expect(find.text('Privacy controls'), findsNothing);
  });
}
