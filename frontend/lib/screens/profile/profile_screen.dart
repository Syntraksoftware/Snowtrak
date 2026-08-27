import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/profile/edit_profile_screen.dart';
import 'package:snowtrak/screens/profile/progress_tab.dart';
import 'package:snowtrak/screens/profile/widgets/profile_home_content.dart';
import 'package:snowtrak/screens/settings/settings_screen.dart';
import 'package:snowtrak/widgets/notification_bell_icon.dart';
import 'package:snowtrak/widgets/profile_header.dart';

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
        backgroundColor: SnowtrakColors.background,
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
            indicatorColor: SnowtrakColors.primary,
            labelColor: SnowtrakColors.primary,
            unselectedLabelColor: SnowtrakColors.textTertiary,
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
                  style: SnowtrakTypography.bodyLarge.copyWith(
                    color: SnowtrakColors.textSecondary,
                  ),
                ),
              );
            }

            final activityProvider = context.read<ActivityProvider>();
            return TabBarView(
              children: [
                RefreshIndicator(
                  color: SnowtrakColors.primary,
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
