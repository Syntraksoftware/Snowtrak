import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/profile/edit_profile_screen.dart';
import 'package:syntrak/screens/profile/widgets/profile_home_content.dart';
import 'package:syntrak/screens/settings/settings_screen.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';
import 'package:syntrak/widgets/notification_bell_icon.dart';
import 'package:syntrak/widgets/profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

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

          return RefreshIndicator(
            color: SnowtrakAuthTheme.brand,
            onRefresh: () async {},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: ProfileHeader()),
                const SliverToBoxAdapter(child: ProfileHomeContent()),
              ],
            ),
          );
        },
      ),
    );
  }
}
