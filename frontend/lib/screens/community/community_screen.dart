import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/community/threads_tab.dart';
import 'package:snowtrak/screens/leaderboard/leaderboard_tab.dart';
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
  // Activity, Clubs and Trails are mock screens with no backend behind them.
  // They stay on disk under screens/groups/ and stop being mounted; deleting
  // them is a cleanup, not part of shipping the board.
  static const _labels = ['Threads', 'Leaderboards'];

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
                  LeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
