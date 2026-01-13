import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Allow Notifications
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Allow Notifications',
                subtitle: 'Receive push notifications',
                value: _pushEnabled,
                onChanged: (value) => setState(() => _pushEnabled = value),
              ),
            ],
          ),

          if (_pushEnabled) ...[
            const SizedBox(height: 24),

            // Activity Notifications
            _buildSectionHeader('ACTIVITY'),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  label: 'Kudos',
                  subtitle: 'When someone gives kudos',
                  value: _kudosNotifications,
                  onChanged: (value) =>
                      setState(() => _kudosNotifications = value),
                ),
                _SettingsToggleRow(
                  label: 'Comments',
                  subtitle: 'When someone comments',
                  value: _commentsNotifications,
                  onChanged: (value) =>
                      setState(() => _commentsNotifications = value),
                ),
                _SettingsToggleRow(
                  label: 'New Followers',
                  subtitle: 'When someone follows you',
                  value: _newFollowers,
                  onChanged: (value) => setState(() => _newFollowers = value),
                ),
                _SettingsToggleRow(
                  label: "Friend's Activities",
                  subtitle: 'When friends complete activities',
                  value: _friendActivities,
                  onChanged: (value) =>
                      setState(() => _friendActivities = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Social Notifications
            _buildSectionHeader('SOCIAL'),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  label: 'Challenge Updates',
                  subtitle: 'Progress and completions',
                  value: _challengeUpdates,
                  onChanged: (value) =>
                      setState(() => _challengeUpdates = value),
                ),
                _SettingsToggleRow(
                  label: 'Group Activity',
                  subtitle: 'Updates from your groups',
                  value: _groupActivity,
                  onChanged: (value) => setState(() => _groupActivity = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weather Notifications
            _buildSectionHeader('WEATHER'),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  label: 'Weather Alerts',
                  subtitle: 'Severe weather warnings',
                  value: _weatherAlerts,
                  onChanged: (value) => setState(() => _weatherAlerts = value),
                ),
                _SettingsToggleRow(
                  label: 'Powder Day Alerts',
                  subtitle: 'Fresh snow notifications',
                  value: _powderDayAlerts,
                  onChanged: (value) =>
                      setState(() => _powderDayAlerts = value),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Email Notifications
          _buildSectionHeader('EMAIL'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Email Notifications',
                subtitle: 'Receive emails from Syntrak',
                value: _emailEnabled,
                onChanged: (value) => setState(() => _emailEnabled = value),
              ),
            ],
          ),

          if (_emailEnabled) ...[
            const SizedBox(height: 16),
            _SettingsGroup(
              children: [
                _SettingsToggleRow(
                  label: 'Weekly Summary',
                  subtitle: 'Your activity highlights',
                  value: _weeklySummary,
                  onChanged: (value) => setState(() => _weeklySummary = value),
                ),
                _SettingsToggleRow(
                  label: 'Monthly Progress Report',
                  subtitle: 'Detailed stats and achievements',
                  value: _monthlyReport,
                  onChanged: (value) => setState(() => _monthlyReport = value),
                ),
                _SettingsToggleRow(
                  label: 'Marketing & Promotions',
                  subtitle: 'Special offers and deals',
                  value: _marketing,
                  onChanged: (value) => setState(() => _marketing = value),
                ),
                _SettingsToggleRow(
                  label: 'Product Updates',
                  subtitle: 'New features and improvements',
                  value: _productUpdates,
                  onChanged: (value) => setState(() => _productUpdates = value),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
        ],
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
}

// iOS-style Settings Group
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
                padding: const EdgeInsets.only(left: 16),
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

// iOS-style Toggle Row
class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
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
                  const SizedBox(height: 2),
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
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF34C759),
          ),
        ],
      ),
    );
  }
}
