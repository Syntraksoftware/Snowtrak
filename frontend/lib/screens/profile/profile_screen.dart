import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/screens/profile/progress_tab.dart';
import 'package:syntrak/screens/profile/activities_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: Navigate to record activity
            },
            tooltip: 'Record Activity',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: BoxDecoration(
              color: SyntrakColors.background,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(SyntrakRadius.md),
                  topRight: Radius.circular(SyntrakRadius.md),
                ),
                color: SyntrakColors.primary.withOpacity(0.1),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.sm,
                vertical: SyntrakSpacing.xs,
              ),
              labelColor: SyntrakColors.primary,
              unselectedLabelColor: SyntrakColors.textTertiary,
              labelStyle: SyntrakTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: SyntrakTypography.labelLarge.copyWith(
                fontSize: 15,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Progress'),
                Tab(text: 'Activities'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<AuthProvider, ActivityProvider>(
        builder: (context, authProvider, activityProvider, _) {
          final user = authProvider.user;
          final activities = activityProvider.activities;

          if (user == null) {
            return Center(
              child: Text(
                'Not logged in',
                style: SyntrakTypography.bodyLarge.copyWith(
                  color: SyntrakColors.textSecondary,
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              ProgressTab(activities: activities),
              ActivitiesTab(activities: activities),
            ],
          );
        },
      ),
    );
  }
}

