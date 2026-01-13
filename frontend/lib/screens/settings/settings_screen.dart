import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/settings/notifications_settings_screen.dart';
import 'package:syntrak/screens/settings/privacy_settings_screen.dart';
import 'package:syntrak/screens/settings/account_settings_screen.dart';
import 'package:syntrak/screens/settings/activity_settings_screen.dart';
import 'package:syntrak/screens/settings/display_settings_screen.dart';
import 'package:syntrak/screens/settings/data_storage_screen.dart';
import 'package:syntrak/screens/settings/help_support_screen.dart';

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
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        backgroundColor: SyntrakColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Profile Card at top
          _buildProfileCard(user),

          const SizedBox(height: SyntrakSpacing.lg),

          // Account Section
          _buildSectionHeader('Account'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.person_outline,
                label: 'Account',
                subtitle: 'Password, email, connected accounts',
                onTap: () => _navigateTo(const AccountSettingsScreen()),
              ),
              _SettingsNavigationRow(
                icon: Icons.lock_outline,
                label: 'Privacy',
                subtitle: 'Profile visibility, blocked users',
                onTap: () => _navigateTo(const PrivacySettingsScreen()),
              ),
              _SettingsNavigationRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: 'Push, email, activity alerts',
                onTap: () => _navigateTo(const NotificationsSettingsScreen()),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.sports_outlined,
                label: 'Activity & Recording',
                subtitle: 'GPS, units, auto-pause',
                onTap: () => _navigateTo(const ActivitySettingsScreen()),
              ),
              _SettingsNavigationRow(
                icon: Icons.palette_outlined,
                label: 'Display',
                subtitle: 'Theme, language, date format',
                onTap: () => _navigateTo(const DisplaySettingsScreen()),
              ),
              _SettingsNavigationRow(
                icon: Icons.storage_outlined,
                label: 'Data & Storage',
                subtitle: 'Cache, offline maps, export',
                onTap: () => _navigateTo(const DataStorageScreen()),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Support Section
          _buildSectionHeader('Support'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.help_outline,
                label: 'Help & Support',
                subtitle: 'FAQ, contact us, report issue',
                onTap: () => _navigateTo(const HelpSupportScreen()),
              ),
              _SettingsNavigationRow(
                icon: Icons.info_outline,
                label: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.xl),

          // Danger Zone
          _buildSectionHeader(''),
          _SettingsGroup(
            children: [
              _SettingsActionRow(
                icon: Icons.logout,
                label: 'Log Out',
                iconColor: SyntrakColors.primary,
                labelColor: SyntrakColors.primary,
                onTap: () => _showLogoutConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsActionRow(
                icon: Icons.delete_outline,
                label: 'Delete Account',
                iconColor: Colors.red,
                labelColor: Colors.red,
                onTap: () => _showDeleteAccountConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.xl),

          // Footer
          Center(
            child: Text(
              'Syntrak v1.0.0',
              style: SyntrakTypography.bodySmall.copyWith(
                color: SyntrakColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: SyntrakSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    final displayName = user?.firstName != null && user?.lastName != null
        ? '${user.firstName} ${user.lastName}'
        : user?.email?.split('@')[0] ?? 'User';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.all(SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: SyntrakColors.primary.withAlpha(30),
            child: Text(
              initial,
              style: SyntrakTypography.headlineMedium.copyWith(
                color: SyntrakColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: SyntrakColors.textSecondary,
            ),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.lg,
        vertical: SyntrakSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: SyntrakTypography.labelSmall.copyWith(
          color: SyntrakColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
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
        title: const Text('About Syntrak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: SyntrakTypography.bodyMedium,
            ),
            const SizedBox(height: SyntrakSpacing.sm),
            Text(
              'A skiing-focused fitness tracking and social community app.',
              style: SyntrakTypography.bodySmall.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            GestureDetector(
              onTap: () {
                // TODO: Open terms of service
              },
              child: Text(
                'Terms of Service',
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.primary,
                ),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.xs),
            GestureDetector(
              onTap: () {
                // TODO: Open privacy policy
              },
              child: Text(
                'Privacy Policy',
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: SyntrakColors.primary),
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
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed after 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Settings Group Container
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: SyntrakColors.surfaceVariant,
              ),
          ],
        ],
      ),
    );
  }
}

// Navigation Row (leads to another screen)
class _SettingsNavigationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;

  const _SettingsNavigationRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SyntrakRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: SyntrakColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: SyntrakColors.textSecondary,
              ),
            ),
            const SizedBox(width: SyntrakSpacing.md),
            // Label and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: SyntrakTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: SyntrakTypography.bodySmall.copyWith(
                        color: SyntrakColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Value or chevron
            if (value != null)
              Text(
                value!,
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
              ),
            const SizedBox(width: SyntrakSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: SyntrakColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// Action Row (performs an action, like logout)
class _SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.icon,
    required this.label,
    this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SyntrakRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (iconColor ?? SyntrakColors.textSecondary).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? SyntrakColors.textSecondary,
              ),
            ),
            const SizedBox(width: SyntrakSpacing.md),
            // Label
            Text(
              label,
              style: SyntrakTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
