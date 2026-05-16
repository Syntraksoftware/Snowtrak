import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ActivitySettingsScreen extends StatefulWidget {
  const ActivitySettingsScreen({super.key});

  @override
  State<ActivitySettingsScreen> createState() => _ActivitySettingsScreenState();
}

class _ActivitySettingsScreenState extends State<ActivitySettingsScreen> {
  String _defaultActivityType = 'Alpine';
  String _gpsAccuracy = 'High';
  bool _autoPause = true;
  bool _autoUpload = true;
  bool _wifiOnly = true;
  bool _liveTracking = false;
  bool _voiceAnnouncements = false;
  String _distanceUnit = 'Kilometers';
  String _elevationUnit = 'Meters';
  String _temperatureUnit = 'Celsius';
  String _speedUnit = 'km/h';

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
          'Activity & Recording',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Defaults
          _buildSectionHeader('DEFAULTS'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                label: 'Activity Type',
                value: _defaultActivityType,
                onTap: () => _showOptions(
                  'Default Activity Type',
                  ['Alpine', 'Backcountry', 'Cross-Country', 'Freestyle'],
                  _defaultActivityType,
                  (v) => setState(() => _defaultActivityType = v),
                ),
              ),
              _SettingsSelectionRow(
                label: 'GPS Accuracy',
                value: _gpsAccuracy,
                onTap: () => _showOptions(
                  'GPS Accuracy',
                  ['High', 'Balanced', 'Battery Saver'],
                  _gpsAccuracy,
                  (v) => setState(() => _gpsAccuracy = v),
                ),
              ),
            ],
          ),
          _buildSectionFooter(
            'Higher GPS accuracy uses more battery but provides better tracking.',
          ),

          const SizedBox(height: 24),

          // Automatic Features
          _buildSectionHeader('AUTOMATIC FEATURES'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Auto-Pause',
                subtitle: 'Pause when you stop moving',
                value: _autoPause,
                onChanged: (v) => setState(() => _autoPause = v),
              ),
              _SettingsToggleRow(
                label: 'Auto-Upload',
                subtitle: 'Upload when activity ends',
                value: _autoUpload,
                onChanged: (v) => setState(() => _autoUpload = v),
              ),
              if (_autoUpload)
                _SettingsToggleRow(
                  label: 'WiFi Only',
                  subtitle: 'Only upload on WiFi',
                  value: _wifiOnly,
                  onChanged: (v) => setState(() => _wifiOnly = v),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Live Features
          _buildSectionHeader('LIVE FEATURES'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Live Tracking',
                subtitle: 'Share your location during activities',
                value: _liveTracking,
                onChanged: (v) => setState(() => _liveTracking = v),
              ),
              _SettingsToggleRow(
                label: 'Voice Announcements',
                subtitle: 'Audio cues for pace and distance',
                value: _voiceAnnouncements,
                onChanged: (v) => setState(() => _voiceAnnouncements = v),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Units
          _buildSectionHeader('UNITS'),
          _SettingsGroup(
            children: [
              _SettingsSelectionRow(
                label: 'Distance',
                value: _distanceUnit,
                onTap: () => _showOptions(
                  'Distance',
                  ['Kilometers', 'Miles'],
                  _distanceUnit,
                  (v) => setState(() => _distanceUnit = v),
                ),
              ),
              _SettingsSelectionRow(
                label: 'Elevation',
                value: _elevationUnit,
                onTap: () => _showOptions(
                  'Elevation',
                  ['Meters', 'Feet'],
                  _elevationUnit,
                  (v) => setState(() => _elevationUnit = v),
                ),
              ),
              _SettingsSelectionRow(
                label: 'Temperature',
                value: _temperatureUnit,
                onTap: () => _showOptions(
                  'Temperature',
                  ['Celsius', 'Fahrenheit'],
                  _temperatureUnit,
                  (v) => setState(() => _temperatureUnit = v),
                ),
              ),
              _SettingsSelectionRow(
                label: 'Speed',
                value: _speedUnit,
                onTap: () => _showOptions(
                  'Speed',
                  ['km/h', 'mph'],
                  _speedUnit,
                  (v) => setState(() => _speedUnit = v),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSectionFooter(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                        const Icon(CupertinoIcons.checkmark,
                            size: 18, color: Color(0xFF007AFF)),
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
                child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[300]),
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
                Text(label,
                    style: const TextStyle(fontSize: 17, color: Colors.black)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
              Text(label,
                  style: const TextStyle(fontSize: 17, color: Colors.black)),
              const Spacer(),
              Text(value,
                  style: TextStyle(fontSize: 17, color: Colors.grey[500])),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
