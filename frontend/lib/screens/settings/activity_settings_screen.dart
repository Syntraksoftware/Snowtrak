import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class ActivitySettingsScreen extends StatefulWidget {
  const ActivitySettingsScreen({super.key});

  @override
  State<ActivitySettingsScreen> createState() => _ActivitySettingsScreenState();
}

class _ActivitySettingsScreenState extends State<ActivitySettingsScreen> {
  // Default settings
  String _defaultActivityType = 'Alpine';
  String _gpsAccuracy = 'High';

  // Auto features
  bool _autoPause = true;
  bool _autoUpload = true;
  bool _wifiOnly = true;

  // Live tracking
  bool _liveTracking = false;
  bool _voiceAnnouncements = false;

  // Units
  String _distanceUnit = 'Kilometers';
  String _elevationUnit = 'Meters';
  String _temperatureUnit = 'Celsius';
  String _speedUnit = 'km/h';

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
        title: const Text('Activity & Recording'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Default Settings Section
          _buildSectionHeader('Defaults'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                icon: Icons.downhill_skiing,
                label: 'Default activity type',
                value: _defaultActivityType,
                options: const [
                  'Alpine',
                  'Backcountry',
                  'Cross-Country',
                  'Freestyle'
                ],
                onChanged: (value) =>
                    setState(() => _defaultActivityType = value),
              ),
              _SettingsSelectionRow(
                icon: Icons.gps_fixed,
                label: 'GPS accuracy',
                value: _gpsAccuracy,
                options: const ['High', 'Balanced', 'Battery Saver'],
                onChanged: (value) => setState(() => _gpsAccuracy = value),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Auto Features Section
          _buildSectionHeader('Automatic Features'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.pause_circle_outline,
                label: 'Auto-pause',
                subtitle: 'Pause recording when you stop moving',
                value: _autoPause,
                onChanged: (value) => setState(() => _autoPause = value),
              ),
              _SettingsToggleRow(
                icon: Icons.cloud_upload_outlined,
                label: 'Auto-upload activities',
                subtitle: 'Upload when activity ends',
                value: _autoUpload,
                onChanged: (value) => setState(() => _autoUpload = value),
              ),
              if (_autoUpload)
                _SettingsToggleRow(
                  icon: Icons.wifi,
                  label: 'WiFi only',
                  subtitle: 'Only upload when connected to WiFi',
                  value: _wifiOnly,
                  onChanged: (value) => setState(() => _wifiOnly = value),
                ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Live Features Section
          _buildSectionHeader('Live Features'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.share_location,
                label: 'Live tracking',
                subtitle: 'Let friends track you during activities',
                value: _liveTracking,
                onChanged: (value) {
                  setState(() => _liveTracking = value);
                  if (value) {
                    _showToast('Friends can now see your live location');
                  }
                },
              ),
              _SettingsToggleRow(
                icon: Icons.record_voice_over_outlined,
                label: 'Voice announcements',
                subtitle: 'Audio cues for pace, distance, time',
                value: _voiceAnnouncements,
                onChanged: (value) =>
                    setState(() => _voiceAnnouncements = value),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Units Section
          _buildSectionHeader('Units'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                icon: Icons.straighten,
                label: 'Distance',
                value: _distanceUnit,
                options: const ['Kilometers', 'Miles'],
                onChanged: (value) => setState(() => _distanceUnit = value),
              ),
              _SettingsSelectionRow(
                icon: Icons.height,
                label: 'Elevation',
                value: _elevationUnit,
                options: const ['Meters', 'Feet'],
                onChanged: (value) => setState(() => _elevationUnit = value),
              ),
              _SettingsSelectionRow(
                icon: Icons.thermostat_outlined,
                label: 'Temperature',
                value: _temperatureUnit,
                options: const ['Celsius', 'Fahrenheit'],
                onChanged: (value) => setState(() => _temperatureUnit = value),
              ),
              _SettingsSelectionRow(
                icon: Icons.speed,
                label: 'Speed',
                value: _speedUnit,
                options: const ['km/h', 'mph'],
                onChanged: (value) => setState(() => _speedUnit = value),
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

// Reusable widgets (same as other settings screens)
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
            child: Icon(icon, size: 20, color: SyntrakColors.textSecondary),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SyntrakTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: SyntrakTypography.bodySmall
                        .copyWith(color: SyntrakColors.textTertiary),
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
              child: Icon(icon, size: 20, color: SyntrakColors.textSecondary),
            ),
            const SizedBox(width: SyntrakSpacing.md),
            Expanded(
              child: Text(
                label,
                style: SyntrakTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              value,
              style: SyntrakTypography.bodySmall
                  .copyWith(color: SyntrakColors.textTertiary),
            ),
            const SizedBox(width: SyntrakSpacing.xs),
            Icon(Icons.chevron_right,
                size: 20, color: SyntrakColors.textTertiary),
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
            Text(
              label,
              style: SyntrakTypography.headlineSmall
                  .copyWith(fontWeight: FontWeight.w600),
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
