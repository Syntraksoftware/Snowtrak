import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/community/threads_tab.dart';
import 'package:snowtrak/screens/groups/active_tab.dart';
import 'package:snowtrak/screens/groups/challenges_tab.dart';
import 'package:snowtrak/screens/groups/clubs_tab.dart';
import 'package:snowtrak/screens/groups/trails_tab.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Community is the social half of the product: the feed plus everything that
/// used to live behind a separate Groups tab, which the design file's five-slot
/// nav has no room for.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  static const _labels = ['Threads', 'Activity', 'Challenges', 'Clubs', 'Trails'];

  late final TabController _tabController =
      TabController(length: _labels.length, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StPageHeader(
              title: 'Community',
              actions: [
                StRoundButton(
                  icon: StIcons.search,
                  tooltip: 'Search',
                  onTap: () {},
                ),
                StRoundButton(
                  icon: StIcons.menu,
                  tooltip: 'More',
                  onTap: () {},
                ),
              ],
              bottom: StTabBar(controller: _tabController, labels: _labels),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ThreadsTab(),
                  ActiveTab(),
                  ChallengesTab(),
                  ClubsTab(),
                  TrailsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
