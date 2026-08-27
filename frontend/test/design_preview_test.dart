@Tags(['preview'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/home/widgets/recent_activity_section.dart';
import 'package:snowtrak/screens/home/widgets/resort_conditions_card.dart';
import 'package:snowtrak/screens/home/widgets/stats_carousel.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Renders the Home tab's pieces without providers so the design can be eyeballed:
/// `flutter test --update-goldens test/design_preview_test.dart` writes
/// `test/goldens/home_preview.png`.
void main() {
  testWidgets('home preview', (tester) async {
    tester.view.physicalSize = const Size(402 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final activities = List.generate(
      3,
      (i) => Activity(
        id: '$i',
        userId: 'u',
        type: ActivityType.alpine,
        name: ['Crystal Mountain', 'Stevens Pass', 'Mt. Baker'][i],
        distance: 22000.0 + i * 4000,
        duration: 9000 + i * 600,
        elevationGain: 4000.0 + i * 500,
        startTime: DateTime(2026, 8, 20 - i, 9),
        endTime: DateTime(2026, 8, 20 - i, 13),
        averagePace: 150,
        maxPace: 42,
        isPublic: true,
        createdAt: DateTime(2026, 8, 20 - i),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SnowtrakTheme.lightTheme,
        home: Scaffold(
          backgroundColor: SnowtrakColors.background,
          body: SafeArea(
            child: Column(
              children: [
                StPageHeader(
                  eyebrow: 'Good morning,',
                  title: 'Alex Johnson',
                  actions: [
                    StRoundButton(icon: StIcons.search, onTap: () {}),
                    StRoundButton(icon: StIcons.bell, badge: true, onTap: () {}),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      ResortConditionsCard(
                        weather: null,
                        isLoading: false,
                        onStartSession: () {},
                        resortName: 'Crystal Mountain',
                      ),
                      const SizedBox(height: 24),
                      StatsCarousel(activities: activities),
                      const SizedBox(height: 24),
                      RecentActivitySection(activities: activities),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: StBottomNav(
            items: const [
              StNavItem(icon: StIcons.home, label: 'Home'),
              StNavItem(icon: StIcons.map, label: 'Map'),
              StNavItem(icon: StIcons.ski, label: 'Record'),
              StNavItem(icon: StIcons.messageChat, label: 'Community'),
              StNavItem(icon: StIcons.profile, label: 'Profile'),
            ],
            currentIndex: 0,
            recordIndex: 2,
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_preview.png'),
    );
  });
}
