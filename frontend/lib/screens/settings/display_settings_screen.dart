import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  String _theme = 'Light';
  String _language = 'English';
  String _dateFormat = 'MM/DD/YYYY';
  String _startOfWeek = 'Sunday';
  String _mapStyle = 'Standard';

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
        title: const Text('Display'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                icon: Icons.brightness_6_outlined,
                label: 'Theme',
                value: _theme,
                options: const ['Light', 'Dark', 'System'],
                onChanged: (value) {
                  setState(() => _theme = value);
                  _showToast('Theme changed to $value');
                },
              ),
              _SettingsNavigationRow(
                icon: Icons.app_shortcut,
                label: 'App icon',
                subtitle: 'Choose your preferred icon',
                onTap: () => _showToast('App icon customization coming soon'),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Language & Region Section
          _buildSectionHeader('Language & Region'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                icon: Icons.language,
                label: 'Language',
                value: _language,
                options: const [
                  'English',
                  'Spanish',
                  'French',
                  'German',
                  'Japanese'
                ],
                onChanged: (value) {
                  setState(() => _language = value);
                  _showToast('Language will change on restart');
                },
              ),
              _SettingsSelectionRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date format',
                value: _dateFormat,
                options: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
                onChanged: (value) => setState(() => _dateFormat = value),
              ),
              _SettingsSelectionRow(
                icon: Icons.view_week_outlined,
                label: 'Start of week',
                value: _startOfWeek,
                options: const ['Sunday', 'Monday', 'Saturday'],
                onChanged: (value) => setState(() => _startOfWeek = value),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Map Section
          _buildSectionHeader('Maps'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                icon: Icons.map_outlined,
                label: 'Map style',
                value: _mapStyle,
                options: const ['Standard', 'Satellite', 'Terrain', 'Dark'],
                onChanged: (value) => setState(() => _mapStyle = value),
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

// Reusable widgets
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
            Icon(Icons.chevron_right,
                size: 20, color: SyntrakColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
