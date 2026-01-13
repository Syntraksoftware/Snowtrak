import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  // Push notification settings
  bool _pushEnabled = true;
  bool _kudosNotifications = true;
  bool _commentsNotifications = true;
  bool _newFollowers = true;
  bool _friendActivities = false;
  bool _challengeUpdates = true;
  bool _groupActivity = true;
  bool _weatherAlerts = true;
  bool _powderDayAlerts = true;

  // Email notification settings
  bool _emailEnabled = true;
  bool _weeklySummary = true;
  bool _monthlyReport = true;
  bool _marketing = false;
  bool _productUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        backgroundColor: SyntrakColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Push Notifications Section
          _buildSectionHeader('Push Notifications'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.notifications_active_outlined,
                label: 'Enable Push Notifications',
                subtitle: 'Receive notifications on your device',
                value: _pushEnabled,
                onChanged: (value) {
                  setState(() => _pushEnabled = value);
                  if (value) {
                    _showToast('Push notifications enabled');
                  }
                },
              ),
            ],
          ),

          if (_pushEnabled) ...[
            const SizedBox(height: SyntrakSpacing.md),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  icon: Icons.favorite_outline,
                  label: 'Kudos',
                  subtitle: 'When someone gives kudos to your activity',
                  value: _kudosNotifications,
                  onChanged: (value) =>
                      setState(() => _kudosNotifications = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comments',
                  subtitle: 'When someone comments on your activity',
                  value: _commentsNotifications,
                  onChanged: (value) =>
                      setState(() => _commentsNotifications = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.person_add_outlined,
                  label: 'New Followers',
                  subtitle: 'When someone follows you',
                  value: _newFollowers,
                  onChanged: (value) => setState(() => _newFollowers = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.group_outlined,
                  label: "Friend's Activities",
                  subtitle: 'When friends complete an activity',
                  value: _friendActivities,
                  onChanged: (value) =>
                      setState(() => _friendActivities = value),
                ),
              ],
            ),
            const SizedBox(height: SyntrakSpacing.md),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Challenge Updates',
                  subtitle: 'Progress and completion notifications',
                  value: _challengeUpdates,
                  onChanged: (value) =>
                      setState(() => _challengeUpdates = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.groups_outlined,
                  label: 'Group Activity',
                  subtitle: 'Updates from your groups and clubs',
                  value: _groupActivity,
                  onChanged: (value) => setState(() => _groupActivity = value),
                ),
              ],
            ),
            const SizedBox(height: SyntrakSpacing.md),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  icon: Icons.cloud_outlined,
                  label: 'Weather Alerts',
                  subtitle: 'Severe weather at favorite resorts',
                  value: _weatherAlerts,
                  onChanged: (value) => setState(() => _weatherAlerts = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.ac_unit,
                  label: 'Powder Day Alerts',
                  subtitle: 'Fresh snow notifications',
                  value: _powderDayAlerts,
                  onChanged: (value) =>
                      setState(() => _powderDayAlerts = value),
                ),
              ],
            ),
          ],

          const SizedBox(height: SyntrakSpacing.xl),

          // Email Notifications Section
          _buildSectionHeader('Email Notifications'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.email_outlined,
                label: 'Enable Email Notifications',
                subtitle: 'Receive emails from Syntrak',
                value: _emailEnabled,
                onChanged: (value) => setState(() => _emailEnabled = value),
              ),
            ],
          ),

          if (_emailEnabled) ...[
            const SizedBox(height: SyntrakSpacing.md),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Weekly Summary',
                  subtitle: 'Your activity highlights every week',
                  value: _weeklySummary,
                  onChanged: (value) => setState(() => _weeklySummary = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.insights_outlined,
                  label: 'Monthly Progress Report',
                  subtitle: 'Detailed stats and achievements',
                  value: _monthlyReport,
                  onChanged: (value) => setState(() => _monthlyReport = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.campaign_outlined,
                  label: 'Marketing & Promotions',
                  subtitle: 'Special offers and partner deals',
                  value: _marketing,
                  onChanged: (value) => setState(() => _marketing = value),
                ),
                _SettingsToggleRow(
                  icon: Icons.new_releases_outlined,
                  label: 'Product Updates',
                  subtitle: 'New features and improvements',
                  value: _productUpdates,
                  onChanged: (value) => setState(() => _productUpdates = value),
                ),
              ],
            ),
          ],

          const SizedBox(height: SyntrakSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
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

// Toggle Row with switch
class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
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
          // Switch
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: SyntrakColors.primary,
          ),
        ],
      ),
    );
  }
}
