import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Help Section
          _buildSectionHeader('Get Help'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.menu_book_outlined,
                label: 'Help Center',
                subtitle: 'FAQ, guides, and tutorials',
                onTap: () => _showToast(context, 'Opening Help Center...'),
              ),
              _SettingsNavigationRow(
                icon: Icons.chat_bubble_outline,
                label: 'Contact Support',
                subtitle: 'Get help from our team',
                onTap: () => _showContactOptions(context),
              ),
              _SettingsNavigationRow(
                icon: Icons.forum_outlined,
                label: 'Community Forum',
                subtitle: 'Ask questions, share tips',
                onTap: () => _showToast(context, 'Opening Community Forum...'),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Feedback Section
          _buildSectionHeader('Feedback'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.bug_report_outlined,
                label: 'Report a Problem',
                subtitle: 'Help us fix issues',
                onTap: () => _showReportDialog(context),
              ),
              _SettingsNavigationRow(
                icon: Icons.lightbulb_outline,
                label: 'Feature Request',
                subtitle: 'Suggest improvements',
                onTap: () => _showFeatureRequestDialog(context),
              ),
              _SettingsNavigationRow(
                icon: Icons.star_outline,
                label: 'Rate Syntrak',
                subtitle: 'Share your experience',
                onTap: () => _showRateDialog(context),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Troubleshooting Section
          _buildSectionHeader('Troubleshooting'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.gps_fixed,
                label: 'GPS Issues',
                subtitle: 'Fix location problems',
                onTap: () => _showGPSHelp(context),
              ),
              _SettingsNavigationRow(
                icon: Icons.sync_problem_outlined,
                label: 'Sync Issues',
                subtitle: 'Resolve sync problems',
                onTap: () => _showSyncHelp(context),
              ),
              _SettingsNavigationRow(
                icon: Icons.battery_alert_outlined,
                label: 'Battery Optimization',
                subtitle: 'Improve battery life',
                onTap: () => _showBatteryHelp(context),
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

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
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
              'Contact Support',
              style: SyntrakTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: const Text('support@syntrak.app'),
              onTap: () {
                Navigator.pop(context);
                _showToast(context, 'Opening email...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9am - 5pm EST'),
              onTap: () {
                Navigator.pop(context);
                _showToast(context, 'Starting chat...');
              },
            ),
            const SizedBox(height: SyntrakSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Problem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please describe the issue you\'re experiencing:',
              style: SyntrakTypography.bodySmall.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the problem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.sm),
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                Expanded(
                  child: Text(
                    'Include device logs',
                    style: SyntrakTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast(context, 'Report submitted. Thank you!');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What feature would you like to see?',
              style: SyntrakTypography.bodySmall.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your idea...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast(context, 'Thanks for your suggestion!');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Syntrak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enjoying Syntrak? Please rate us on the App Store!',
              style: SyntrakTypography.bodyMedium,
            ),
            const SizedBox(height: SyntrakSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < 4 ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast(context, 'Opening App Store...');
            },
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }

  void _showGPSHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Troubleshooting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1. Check location permissions in Settings'),
            _buildHelpItem('2. Enable High Accuracy GPS mode'),
            _buildHelpItem('3. Wait for GPS signal before starting'),
            _buildHelpItem('4. Avoid tall buildings and dense forests'),
            _buildHelpItem('5. Restart your device if issues persist'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showSyncHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Troubleshooting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1. Check your internet connection'),
            _buildHelpItem('2. Try switching between WiFi and cellular'),
            _buildHelpItem('3. Force close and reopen the app'),
            _buildHelpItem('4. Check for app updates'),
            _buildHelpItem('5. Try logging out and back in'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showBatteryHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battery Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1. Use "Battery Saver" GPS mode'),
            _buildHelpItem('2. Disable live tracking when not needed'),
            _buildHelpItem('3. Lower screen brightness'),
            _buildHelpItem('4. Close other apps while recording'),
            _buildHelpItem('5. Keep your phone warm in cold weather'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: SyntrakTypography.bodySmall,
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
