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
                  Tab(text: 'Progress'),
                  Tab(text: 'Activities'),
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

