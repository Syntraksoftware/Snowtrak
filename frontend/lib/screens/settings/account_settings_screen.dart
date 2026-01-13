import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final email = user?.email ?? 'Not set';

    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        backgroundColor: SyntrakColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Email & Phone Section
          _buildSectionHeader('Contact Information'),
          _SettingsGroup(
            children: [
              _SettingsInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Verified',
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () => _showChangeEmailDialog(),
              ),
              _SettingsInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone number',
                value: 'Not set',
                onTap: () => _showAddPhoneDialog(),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Security Section
          _buildSectionHeader('Security'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.lock_outline,
                label: 'Change password',
                subtitle: 'Update your password',
                onTap: () => _showChangePasswordDialog(),
              ),
              _SettingsToggleRow(
                icon: Icons.security_outlined,
                label: 'Two-factor authentication',
                subtitle: _twoFactorEnabled ? 'Enabled' : 'Add extra security',
                value: _twoFactorEnabled,
                onChanged: (value) {
                  setState(() => _twoFactorEnabled = value);
                  if (value) {
                    _showSetup2FADialog();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Connected Accounts Section
          _buildSectionHeader('Connected Accounts'),
          _SettingsGroup(
            children: [
              _SettingsConnectedAccountRow(
                icon: Icons.g_mobiledata,
                label: 'Google',
                isConnected: false,
                onTap: () => _showToast('Google connection coming soon'),
              ),
              _SettingsConnectedAccountRow(
                icon: Icons.apple,
                label: 'Apple',
                isConnected: false,
                onTap: () => _showToast('Apple connection coming soon'),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Sessions Section
          _buildSectionHeader('Sessions'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.devices_outlined,
                label: 'Active sessions',
                subtitle: '1 device logged in',
                onTap: () => _showToast('Active sessions coming soon'),
              ),
              _SettingsActionRow(
                icon: Icons.logout,
                label: 'Log out of all devices',
                onTap: () => _showLogoutAllConfirmation(),
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

  void _showChangeEmailDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New email address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Verification email sent');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddPhoneDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            border: OutlineInputBorder(),
            prefixText: '+1 ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Verification code sent');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
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
              _showToast('Password updated successfully');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSetup2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Up Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a method to receive verification codes:',
              style: SyntrakTypography.bodyMedium,
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('SMS'),
              subtitle: const Text('Receive codes via text message'),
              onTap: () {
                Navigator.pop(context);
                _showToast('SMS 2FA setup coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text('Authenticator App'),
              subtitle: const Text('Use Google Authenticator or similar'),
              onTap: () {
                Navigator.pop(context);
                _showToast('Authenticator setup coming soon');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _twoFactorEnabled = false);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out of All Devices'),
        content: const Text(
          'This will log you out of all devices including this one. You will need to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Log Out All',
              style: TextStyle(color: SyntrakColors.primary),
            ),
          ),
        ],
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

// Info Row (displays a value)
class _SettingsInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
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
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: SyntrakTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null) ...[
              const SizedBox(width: SyntrakSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: SyntrakColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Toggle Row
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

// Action Row
class _SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.icon,
    required this.label,
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
            Text(
              label,
              style: SyntrakTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Connected Account Row
class _SettingsConnectedAccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isConnected;
  final VoidCallback onTap;

  const _SettingsConnectedAccountRow({
    required this.icon,
    required this.label,
    required this.isConnected,
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
              child: Text(
                label,
                style: SyntrakTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isConnected
                    ? SyntrakColors.surfaceVariant
                    : SyntrakColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isConnected ? 'Connected' : 'Connect',
                style: SyntrakTypography.labelSmall.copyWith(
                  color: isConnected
                      ? SyntrakColors.textSecondary
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
