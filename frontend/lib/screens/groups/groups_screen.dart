import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/groups/active_tab.dart';
import 'package:syntrak/screens/groups/challenges_tab.dart';
import 'package:syntrak/screens/groups/clubs_tab.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings functionality
            },
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: SyntrakColors.primary,
                indicatorWeight: 3,
                labelColor: SyntrakColors.textPrimary,
                unselectedLabelColor: SyntrakColors.textTertiary,
                labelStyle: SyntrakTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: SyntrakTypography.labelLarge,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Challenges'),
                  Tab(text: 'Clubs'),
                ],
              ),
              Divider(
                height: 1,
                color: SyntrakColors.divider,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActiveTab(),
          ChallengesTab(),
          ClubsTab(),
        ],
      ),
    );
  }
}

