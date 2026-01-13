import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _profileVisibility = 'Everyone';
  String _activityVisibility = 'Followers';
  bool _hideStartEnd = true;
  bool _hideExactLocation = false;
  bool _showActivityMaps = true;
  bool _discoverableByEmail = true;
  bool _discoverableByPhone = false;
  bool _hideFromLeaderboards = false;

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
          'Privacy & Security',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Profile Visibility
          _buildSectionHeader('PROFILE VISIBILITY'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                label: 'Profile',
                value: _profileVisibility,
                onTap: () => _showOptions(
                  'Who can see your profile',
                  ['Everyone', 'Followers', 'Only Me'],
                  _profileVisibility,
                  (value) => setState(() => _profileVisibility = value),
                ),
              ),
              _SettingsSelectionRow(
                label: 'Activities',
                value: _activityVisibility,
                onTap: () => _showOptions(
                  'Who can see your activities',
                  ['Everyone', 'Followers', 'Only Me'],
                  _activityVisibility,
                  (value) => setState(() => _activityVisibility = value),
                ),
              ),
            ],
          ),
          _buildSectionFooter(
            'Control who can see your profile and activities.',
          ),

          const SizedBox(height: 24),

          // Location Privacy
          _buildSectionHeader('LOCATION PRIVACY'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Hide Start & End Points',
                subtitle: 'Protects your home location',
                value: _hideStartEnd,
                onChanged: (value) => setState(() => _hideStartEnd = value),
              ),
              _SettingsToggleRow(
                label: 'Hide Exact Location',
                subtitle: 'Show general area instead',
                value: _hideExactLocation,
                onChanged: (value) =>
                    setState(() => _hideExactLocation = value),
              ),
              _SettingsToggleRow(
                label: 'Show Activity Maps',
                subtitle: 'Display route on activities',
                value: _showActivityMaps,
                onChanged: (value) =>
                    setState(() => _showActivityMaps = value),
              ),
            ],
          ),
          _buildSectionFooter(
            'Your start and end points will be hidden within 500m to protect your privacy.',
          ),

          const SizedBox(height: 24),

          // Discoverability
          _buildSectionHeader('DISCOVERABILITY'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Find by Email',
                subtitle: 'Let others find you by email',
                value: _discoverableByEmail,
                onChanged: (value) =>
                    setState(() => _discoverableByEmail = value),
              ),
              _SettingsToggleRow(
                label: 'Find by Phone',
                subtitle: 'Let others find you by phone',
                value: _discoverableByPhone,
                onChanged: (value) =>
                    setState(() => _discoverableByPhone = value),
              ),
              _SettingsToggleRow(
                label: 'Hide from Leaderboards',
                subtitle: 'Opt out of public rankings',
                value: _hideFromLeaderboards,
                onChanged: (value) =>
                    setState(() => _hideFromLeaderboards = value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Blocked Users
          _buildSectionHeader('BLOCKED ACCOUNTS'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                label: 'Blocked Users',
                value: '0 users',
                onTap: () => _showToast('Blocked users coming soon'),
              ),
              _SettingsNavigationRow(
                label: 'Muted Users',
                value: '0 users',
                onTap: () => _showToast('Muted users coming soon'),
              ),
            ],
          ),

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

  Widget _buildSectionFooter(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  void _showOptions(
    String title,
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: options
            .map((option) => CupertinoActionSheetAction(
                  onPressed: () {
                    onChanged(option);
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(option),
                      if (option == currentValue) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.checkmark,
                          size: 18,
                          color: Color(0xFF007AFF),
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Reusable widgets
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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

class _SettingsSelectionRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsSelectionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(fontSize: 17, color: Colors.grey[500]),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNavigationRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsNavigationRow({
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(fontSize: 17, color: Colors.grey[500]),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
