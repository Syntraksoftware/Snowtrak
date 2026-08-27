import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:flutter/cupertino.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  String _language = 'English';
  String _dateFormat = 'MM/DD/YYYY';
  String _startOfWeek = 'Sunday';
  String _mapStyle = 'Standard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Display & Appearance',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Appearance
          _buildSectionHeader('APPEARANCE'),
          _SettingsGroup(
            children: [
              // ponytail: offered Light/Dark/System and did nothing but toast.
              // main.dart pins themeMode to light, and the screens are only
              // part-way onto the palette, so a working picker would ship a
              // half-broken dark mode. Restore the selection row here once
              // docs/frontend_design_system.md Phase 4 is done.
              _SettingsNavigationRow(
                label: 'Theme',
                value: 'Light',
                onTap: () => _showToast('Dark mode is in progress'),
              ),
              _SettingsNavigationRow(
                label: 'App Icon',
                value: 'Default',
                onTap: () => _showToast('App icon customization coming soon'),
              ),
            ],
          ),
          _buildSectionFooter(
            'Snowtrak is light for now. Dark mode is on the way.',
          ),

          const SizedBox(height: 24),

          // Language & Region
          _buildSectionHeader('LANGUAGE & REGION'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                label: 'Language',
                value: _language,
                onTap: () => _showOptions(
                  'Language',
                  ['English', 'Spanish', 'French', 'German', 'Japanese'],
                  _language,
                  (v) {
                    setState(() => _language = v);
                    _showToast('Language will change on restart');
                  },
                ),
              ),
              _SettingsSelectionRow(
                label: 'Date Format',
                value: _dateFormat,
                onTap: () => _showOptions(
                  'Date Format',
                  ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
                  _dateFormat,
                  (v) => setState(() => _dateFormat = v),
                ),
              ),
              _SettingsSelectionRow(
                label: 'Start of Week',
                value: _startOfWeek,
                onTap: () => _showOptions(
                  'Start of Week',
                  ['Sunday', 'Monday', 'Saturday'],
                  _startOfWeek,
                  (v) => setState(() => _startOfWeek = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Maps
          _buildSectionHeader('MAPS'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                label: 'Map Style',
                value: _mapStyle,
                onTap: () => _showOptions(
                  'Map Style',
                  ['Standard', 'Satellite', 'Terrain', 'Dark'],
                  _mapStyle,
                  (v) => setState(() => _mapStyle = v),
                ),
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
        style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
      ),
    );
  }

  Widget _buildSectionFooter(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
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
                        Icon(CupertinoIcons.checkmark,
                            size: 18, color: context.colors.primary),
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
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Divider(height: 0.5, thickness: 0.5, color: context.colors.divider),
              ),
          ],
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
              Text(label,
                  style: TextStyle(fontSize: 17, color: context.colors.textPrimary)),
              const Spacer(),
              Text(value,
                  style: TextStyle(fontSize: 17, color: context.colors.textSecondary)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: context.colors.textTertiary, size: 20),
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
              Text(label,
                  style: TextStyle(fontSize: 17, color: context.colors.textPrimary)),
              const Spacer(),
              if (value != null)
                Text(value!,
                    style: TextStyle(fontSize: 17, color: context.colors.textSecondary)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: context.colors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
