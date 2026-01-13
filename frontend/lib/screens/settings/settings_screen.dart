import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      backgroundColor: const Color(0xFFF2F2F7), // iOS system background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
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
          _buildProfileCard(user),

          const SizedBox(height: 24),

          // Most Important First: Notifications & Privacy
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.notifications,
                iconBackground: const Color(0xFFFF3B30), // iOS Red
                label: 'Notifications',
                onTap: () => _navigateTo(const NotificationsSettingsScreen()),
              ),
              _SettingsRow(
                icon: Icons.lock,
                iconBackground: const Color(0xFF34C759), // iOS Green
                label: 'Privacy & Security',
                onTap: () => _navigateTo(const PrivacySettingsScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account & Personalization
          _buildSectionHeader('ACCOUNT'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.person,
                iconBackground: const Color(0xFF007AFF), // iOS Blue
                label: 'Account',
                subtitle: 'Password, email, security',
                onTap: () => _navigateTo(const AccountSettingsScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings
          _buildSectionHeader('APP'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.downhill_skiing,
                iconBackground: const Color(0xFFFF9500), // iOS Orange
                label: 'Activity & Recording',
                subtitle: 'GPS, units, auto-pause',
                onTap: () => _navigateTo(const ActivitySettingsScreen()),
              ),
              _SettingsRow(
                icon: Icons.display_settings,
                iconBackground: const Color(0xFF5856D6), // iOS Purple
                label: 'Display & Appearance',
                subtitle: 'Theme, language, date format',
                onTap: () => _navigateTo(const DisplaySettingsScreen()),
              ),
              _SettingsRow(
                icon: Icons.storage,
                iconBackground: const Color(0xFF8E8E93), // iOS Gray
                label: 'Data & Storage',
                subtitle: 'Cache, offline maps, export',
                onTap: () => _navigateTo(const DataStorageScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support
          _buildSectionHeader('SUPPORT'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.help,
                iconBackground: const Color(0xFF007AFF), // iOS Blue
                label: 'Help & Support',
                onTap: () => _navigateTo(const HelpSupportScreen()),
              ),
              _SettingsRow(
                icon: Icons.info,
                iconBackground: const Color(0xFF8E8E93), // iOS Gray
                label: 'About Syntrak',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Sign Out - separate group at bottom
          _SettingsGroup(
            children: [
              _SettingsActionRow(
                label: 'Sign Out',
                textColor: const Color(0xFF007AFF),
                onTap: () => _showLogoutConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Delete Account - dangerous action at very bottom
          _SettingsGroup(
            children: [
              _SettingsActionRow(
                label: 'Delete Account',
                textColor: const Color(0xFFFF3B30),
                onTap: () => _showDeleteAccountConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Syntrak v1.0.0 (Build 1)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // iOS-style profile card (like Apple ID)
  Widget _buildProfileCard(dynamic user) {
    final displayName = user?.firstName != null && user?.lastName != null
        ? '${user.firstName} ${user.lastName}'
        : user?.email?.split('@')[0] ?? 'User';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to profile editing
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Large avatar like Apple ID
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF007AFF),
                        const Color(0xFF5856D6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profile, Subscriptions & more',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.grey[600],
          letterSpacing: -0.1,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('About Syntrak'),
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
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFFF3B30)),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF007AFF)),
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );
  }
}

// iOS-style Settings Group (white rounded container)
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: Colors.grey[300],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// iOS-style Settings Row with colored icon
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconBackground,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Colored icon container (iOS style)
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Label and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// iOS-style Action Row (centered text, no icon)
class _SettingsActionRow extends StatelessWidget {
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
