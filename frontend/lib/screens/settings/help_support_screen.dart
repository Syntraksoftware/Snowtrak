import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'Help & Support',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Get Help
          _buildSectionHeader('GET HELP'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.menu_book,
                iconBackground: const Color(0xFF007AFF),
                label: 'Help Center',
                subtitle: 'FAQ, guides, tutorials',
                onTap: () => _showToast(context, 'Opening Help Center...'),
              ),
              _SettingsRow(
                icon: Icons.chat_bubble,
                iconBackground: const Color(0xFF34C759),
                label: 'Contact Support',
                subtitle: 'Get help from our team',
                onTap: () => _showContactOptions(context),
              ),
              _SettingsRow(
                icon: Icons.forum,
                iconBackground: const Color(0xFFFF9500),
                label: 'Community Forum',
                subtitle: 'Ask questions, share tips',
                onTap: () => _showToast(context, 'Opening Community...'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Feedback
          _buildSectionHeader('FEEDBACK'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.bug_report,
                iconBackground: const Color(0xFFFF3B30),
                label: 'Report a Problem',
                onTap: () => _showReportDialog(context),
              ),
              _SettingsRow(
                icon: Icons.lightbulb,
                iconBackground: const Color(0xFFFFCC00),
                label: 'Feature Request',
                onTap: () => _showFeatureRequestDialog(context),
              ),
              _SettingsRow(
                icon: Icons.star,
                iconBackground: const Color(0xFF5856D6),
                label: 'Rate Syntrak',
                onTap: () => _showRateDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Troubleshooting
          _buildSectionHeader('TROUBLESHOOTING'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.gps_fixed,
                iconBackground: const Color(0xFF8E8E93),
                label: 'GPS Issues',
                onTap: () => _showGPSHelp(context),
              ),
              _SettingsRow(
                icon: Icons.sync_problem,
                iconBackground: const Color(0xFF8E8E93),
                label: 'Sync Issues',
                onTap: () => _showSyncHelp(context),
              ),
              _SettingsRow(
                icon: Icons.battery_alert,
                iconBackground: const Color(0xFF8E8E93),
                label: 'Battery Optimization',
                onTap: () => _showBatteryHelp(context),
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
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showContactOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Contact Support'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(context, 'Opening email...');
            },
            child: const Text('Email (support@syntrak.app)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(context, 'Starting chat...');
            },
            child: const Text('Live Chat'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Report a Problem'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            placeholder: 'Describe the issue...',
            maxLines: 4,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(context, 'Report submitted. Thank you!');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Feature Request'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            placeholder: 'Describe your idea...',
            maxLines: 4,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(context, 'Thanks for your suggestion!');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Rate Syntrak'),
        content: const Text('Enjoying Syntrak? Please rate us on the App Store!'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(context, 'Opening App Store...');
            },
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }

  void _showGPSHelp(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('GPS Troubleshooting'),
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            '1. Check location permissions\n'
            '2. Enable High Accuracy mode\n'
            '3. Wait for GPS signal before starting\n'
            '4. Avoid tall buildings\n'
            '5. Restart device if issues persist',
            textAlign: TextAlign.left,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showSyncHelp(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sync Troubleshooting'),
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            '1. Check internet connection\n'
            '2. Try WiFi or cellular\n'
            '3. Force close and reopen app\n'
            '4. Check for updates\n'
            '5. Try logging out and back in',
            textAlign: TextAlign.left,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showBatteryHelp(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Battery Tips'),
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            '1. Use "Battery Saver" GPS mode\n'
            '2. Disable live tracking\n'
            '3. Lower screen brightness\n'
            '4. Close other apps\n'
            '5. Keep phone warm in cold weather',
            textAlign: TextAlign.left,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
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
                padding: const EdgeInsets.only(left: 52),
                child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[300]),
              ),
          ],
        ],
      ),
    );
  }
}

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
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 17, color: Colors.black)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
