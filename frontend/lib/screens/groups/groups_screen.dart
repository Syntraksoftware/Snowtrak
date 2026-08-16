import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/groups/active_tab.dart';
import 'package:snowtrak/screens/groups/challenges_tab.dart';
import 'package:snowtrak/screens/groups/clubs_tab.dart';
import 'package:snowtrak/screens/groups/trails_tab.dart';
import 'package:snowtrak/screens/groups/widgets/groups_tab_bar.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnowtrakColors.background,
      appBar: AppBar(
        title: const Text('Groups'),
        centerTitle: false,
        titleSpacing: SnowtrakSpacing.md,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: SnowtrakColors.surface,
        foregroundColor: SnowtrakColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implement search functionality
            },
            tooltip: 'Search',
          ),
        ],
        bottom: GroupsTabBar(controller: _tabController),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActiveTab(),
          ChallengesTab(),
          ClubsTab(),
          TrailsTab(),
        ],
      ),
    );
  }
}
