import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Profile visibility
  String _profileVisibility = 'Everyone';
  String _activityVisibility = 'Followers';

  // Location privacy
  bool _hideStartEnd = true;
  double _privacyZoneRadius = 500; // meters
  bool _hideExactLocation = false;
  bool _showActivityMaps = true;

  // Discovery
  bool _discoverableByEmail = true;
  bool _discoverableByPhone = false;
  bool _hideFromLeaderboards = false;

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
        title: const Text('Privacy'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Profile Visibility Section
          _buildSectionHeader('Profile Visibility'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                icon: Icons.visibility_outlined,
                label: 'Who can see your profile',
                value: _profileVisibility,
                options: const ['Everyone', 'Followers', 'Only Me'],
                onChanged: (value) =>
                    setState(() => _profileVisibility = value),
              ),
              _SettingsSelectionRow(
                icon: Icons.directions_run,
                label: 'Who can see your activities',
                value: _activityVisibility,
                options: const ['Everyone', 'Followers', 'Only Me'],
                onChanged: (value) =>
                    setState(() => _activityVisibility = value),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Location Privacy Section
          _buildSectionHeader('Location Privacy'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.location_off_outlined,
                label: 'Hide start & end points',
                subtitle: 'Protect your home and frequent locations',
                value: _hideStartEnd,
                onChanged: (value) {
                  setState(() => _hideStartEnd = value);
                  if (value) {
                    _showToast('Your start and end points will be hidden');
                  }
                },
              ),
              if (_hideStartEnd)
                _SettingsSliderRow(
                  icon: Icons.radar,
                  label: 'Privacy zone radius',
                  subtitle: '${_privacyZoneRadius.toInt()}m around start/end',
                  value: _privacyZoneRadius,
                  min: 200,
                  max: 1000,
                  divisions: 8,
                  onChanged: (value) =>
                      setState(() => _privacyZoneRadius = value),
                ),
              _SettingsToggleRow(
                icon: Icons.my_location_outlined,
                label: 'Hide exact location in posts',
                subtitle: 'Show general area instead of precise location',
                value: _hideExactLocation,
                onChanged: (value) =>
                    setState(() => _hideExactLocation = value),
              ),
              _SettingsToggleRow(
                icon: Icons.map_outlined,
                label: 'Show activity maps',
                subtitle: 'Display route maps on public activities',
                value: _showActivityMaps,
                onChanged: (value) =>
                    setState(() => _showActivityMaps = value),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Discovery Section
          _buildSectionHeader('Discoverability'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.email_outlined,
                label: 'Find by email',
                subtitle: 'Let others find you using your email',
                value: _discoverableByEmail,
                onChanged: (value) =>
                    setState(() => _discoverableByEmail = value),
              ),
              _SettingsToggleRow(
                icon: Icons.phone_outlined,
                label: 'Find by phone number',
                subtitle: 'Let others find you using your phone',
                value: _discoverableByPhone,
                onChanged: (value) =>
                    setState(() => _discoverableByPhone = value),
              ),
              _SettingsToggleRow(
                icon: Icons.leaderboard_outlined,
                label: 'Hide from leaderboards',
                subtitle: 'Opt out of public rankings',
                value: _hideFromLeaderboards,
                onChanged: (value) =>
                    setState(() => _hideFromLeaderboards = value),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Blocked Users Section
          _buildSectionHeader('Blocked & Muted'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.block,
                label: 'Blocked users',
                subtitle: '0 users blocked',
                onTap: () {
                  // TODO: Navigate to blocked users
                  _showToast('Blocked users list coming soon');
                },
              ),
              _SettingsNavigationRow(
                icon: Icons.volume_off_outlined,
                label: 'Muted users',
                subtitle: '0 users muted',
                onTap: () {
                  // TODO: Navigate to muted users
                  _showToast('Muted users list coming soon');
                },
              ),
            ],
          ),

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

// Selection Row (opens bottom sheet with options)
class _SettingsSelectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SettingsSelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showOptionsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Text(
                label,
                style: SyntrakTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
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

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SyntrakColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SyntrakSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SyntrakColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.lg),
              child: Text(
                label,
                style: SyntrakTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ...options.map((option) => ListTile(
                  title: Text(option),
                  trailing: option == value
                      ? Icon(Icons.check, color: SyntrakColors.primary)
                      : null,
                  onTap: () {
                    onChanged(option);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: SyntrakSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// Slider Row
class _SettingsSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SettingsSliderRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
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
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: SyntrakColors.primary,
              inactiveTrackColor: SyntrakColors.surfaceVariant,
              thumbColor: SyntrakColors.primary,
              overlayColor: SyntrakColors.primary.withAlpha(30),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// Navigation Row
class _SettingsNavigationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsNavigationRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
        child: Row(
          children: [
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
