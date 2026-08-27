import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/settings/notifications_settings_screen.dart';
import 'package:snowtrak/screens/settings/privacy_settings_screen.dart';
import 'package:snowtrak/screens/settings/account_settings_screen.dart';
import 'package:snowtrak/screens/settings/activity_settings_screen.dart';
import 'package:snowtrak/screens/settings/display_settings_screen.dart';
import 'package:snowtrak/screens/settings/data_storage_screen.dart';
import 'package:snowtrak/screens/settings/help_support_screen.dart';
import 'package:snowtrak/screens/settings/widgets/settings_ios_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: context.colors.background, // iOS system background
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Profile Card - iOS Style (like Apple ID card)
          SettingsIosProfileCard(user: user),

          const SizedBox(height: 24),

          // Most Important First: Notifications & Privacy
          SettingsIosGroup(
            children: [
              SettingsIosRow(
                icon: Icons.notifications,
                iconBackground: SnowtrakColors.tileRed,
                label: 'Notifications',
                onTap: () => _navigateTo(const NotificationsSettingsScreen()),
              ),
              SettingsIosRow(
                icon: Icons.lock,
                iconBackground: SnowtrakColors.tileGreen,
                label: 'Privacy & Security',
                onTap: () => _navigateTo(const PrivacySettingsScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account & Personalization
          const SettingsIosSectionHeader('ACCOUNT'),
          SettingsIosGroup(
            children: [
              SettingsIosRow(
                icon: Icons.person,
                iconBackground: SnowtrakColors.tileInk,
                label: 'Account',
                subtitle: 'Password, email, security',
                onTap: () => _navigateTo(const AccountSettingsScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings
          const SettingsIosSectionHeader('APP'),
          SettingsIosGroup(
            children: [
              SettingsIosRow(
                icon: Icons.downhill_skiing,
                iconBackground: SnowtrakColors.tileOrange,
                label: 'Activity & Recording',
                subtitle: 'GPS, units, auto-pause',
                onTap: () => _navigateTo(const ActivitySettingsScreen()),
              ),
              SettingsIosRow(
                icon: Icons.display_settings,
                iconBackground: SnowtrakColors.tileSlate,
                label: 'Display & Appearance',
                subtitle: 'Theme, language, date format',
                onTap: () => _navigateTo(const DisplaySettingsScreen()),
              ),
              SettingsIosRow(
                icon: Icons.storage,
                iconBackground: SnowtrakColors.tileGrey,
                label: 'Data & Storage',
                subtitle: 'Cache, offline maps, export',
                onTap: () => _navigateTo(const DataStorageScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support
          const SettingsIosSectionHeader('SUPPORT'),
          SettingsIosGroup(
            children: [
              SettingsIosRow(
                icon: Icons.help,
                iconBackground: SnowtrakColors.tileInk,
                label: 'Help & Support',
                onTap: () => _navigateTo(const HelpSupportScreen()),
              ),
              SettingsIosRow(
                icon: Icons.info,
                iconBackground: SnowtrakColors.tileGrey,
                label: 'About Snowtrak',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Sign Out - separate group at bottom
          SettingsIosGroup(
            children: [
              SettingsIosActionRow(
                label: 'Sign Out',
                textColor: context.colors.primary,
                onTap: () => _showLogoutConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Delete Account - dangerous action at very bottom
          SettingsIosGroup(
            children: [
              SettingsIosActionRow(
                label: 'Delete Account',
                textColor: context.colors.error,
                onTap: () => _showDeleteAccountConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Snowtrak v1.0.0 (Build 1)',
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('About Snowtrak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0 (Build 1)',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              'A skiing-focused fitness tracking and social community app.',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(color: context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(dialogContext);
              
              // Get auth provider and logout
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              // Pop all routes to return to root - the main Consumer will
              // automatically show LoginScreen when isAuthenticated is false
              // State.context, so the State's own mounted is the right
              // guard -- context.mounted answers a different question.
              if (mounted) {
                Navigator.of(context, rootNavigator: true)
                    .popUntil((route) => route.isFirst);
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }
}
