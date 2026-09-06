import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/profile/edit_profile_screen.dart';
import 'package:snowtrak/screens/profile/progress_tab.dart';
import 'package:snowtrak/screens/profile/widgets/profile_home_content.dart';
import 'package:snowtrak/screens/profile/widgets/profile_totals.dart';
import 'package:snowtrak/screens/settings/settings_screen.dart';
import 'package:snowtrak/ui/st/st.dart';
import 'package:snowtrak/widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  static const _labels = ['Overview', 'Progress'];

  late final TabController _tabController =
      TabController(length: _labels.length, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StPageHeader(
              title: 'My Profile',
              actions: [
                StRoundButton(
                  icon: StIcons.bookmark,
                  tooltip: 'Edit profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
                StRoundButton(
                  icon: StIcons.settings,
                  tooltip: 'Settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
              bottom: StTabBar(controller: _tabController, labels: _labels),
            ),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.user == null) {
                    return Center(
                      child: Text(
                        'Not logged in',
                        style: SnowtrakTypography.bodyLarge.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final activityProvider = context.read<ActivityProvider>();
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        color: context.colors.primary,
                        onRefresh: () => activityProvider.loadActivities(
                          refresh: true,
                          forceNetwork: true,
                        ),
                        child: const CustomScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: ProfileHeader()),
                            SliverToBoxAdapter(child: _OwnTotals()),
                            SliverToBoxAdapter(child: ProfileHomeContent()),
                          ],
                        ),
                      ),
                      const ProgressTab(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feeds [ProfileTotals] from the signed-in user's lifetime stats.
class _OwnTotals extends StatelessWidget {
  const _OwnTotals();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) => ProfileTotals(stats: provider.stats),
    );
  }
}
