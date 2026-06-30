import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/profile/edit_profile_screen.dart';
import 'package:syntrak/screens/profile/progress_tab.dart';
import 'package:syntrak/screens/profile/widgets/profile_home_content.dart';
import 'package:syntrak/screens/settings/settings_screen.dart';
import 'package:syntrak/widgets/notification_bell_icon.dart';
import 'package:syntrak/widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: SyntrakColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            const NotificationBellIcon(),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: SyntrakColors.primary,
            labelColor: SyntrakColors.primary,
            unselectedLabelColor: SyntrakColors.textTertiary,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.user == null) {
              return Center(
                child: Text(
                  'Not logged in',
                  style: SyntrakTypography.bodyLarge.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
              );
            }

            final activityProvider = context.read<ActivityProvider>();
            return TabBarView(
              children: [
                RefreshIndicator(
                  color: SyntrakColors.primary,
                  onRefresh: () => activityProvider.loadActivities(
                    refresh: true,
                    forceNetwork: true,
                  ),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: ProfileHeader()),
                      const SliverToBoxAdapter(child: ProfileHomeContent()),
                    ],
                  ),
                ),
                const ProgressTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}
