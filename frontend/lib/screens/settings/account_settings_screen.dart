import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
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
          'Account',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Contact Information
          _buildSectionHeader('CONTACT INFORMATION'),
          _SettingsGroup(
            children: [
              _SettingsDetailRow(
                label: 'Email',
                value: email,
                trailing: _buildVerifiedBadge(),
                onTap: () => _showChangeEmailDialog(),
              ),
              _SettingsDetailRow(
                label: 'Phone',
                value: 'Not set',
                onTap: () => _showAddPhoneDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security
          _buildSectionHeader('SECURITY'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                label: 'Change Password',
                onTap: () => _showChangePasswordDialog(),
              ),
              _SettingsToggleRow(
                label: 'Two-Factor Authentication',
                value: _twoFactorEnabled,
                onChanged: (value) {
                  setState(() => _twoFactorEnabled = value);
                  if (value) _showSetup2FADialog();
                },
              ),
            ],
          ),
          _buildSectionFooter(
            'Two-factor authentication adds an extra layer of security to your account.',
          ),

          const SizedBox(height: 24),

          // Connected Accounts
          _buildSectionHeader('CONNECTED ACCOUNTS'),
          _SettingsGroup(
            children: [
              _SettingsConnectedRow(
                label: 'Google',
                icon: Icons.g_mobiledata,
                isConnected: false,
                onTap: () => _showToast('Google connection coming soon'),
              ),
              _SettingsConnectedRow(
                label: 'Apple',
                icon: Icons.apple,
                isConnected: false,
                onTap: () => _showToast('Apple connection coming soon'),
              ),
            ],
          ),
          _buildSectionFooter(
            'Connect accounts for easier sign-in.',
          ),

          const SizedBox(height: 24),

          // Sessions
          _buildSectionHeader('SESSIONS'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                label: 'Active Sessions',
                value: '1 device',
                onTap: () => _showToast('Active sessions coming soon'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SettingsGroup(
            children: [
              _SettingsActionRow(
                label: 'Sign Out of All Devices',
                textColor: const Color(0xFF007AFF),
                onTap: () => _showLogoutAllConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Verified',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF34C759),
        ),
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
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      ),
    );
  }

  void _showChangeEmailDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change Email'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            placeholder: 'New email address',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Phone Number'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            placeholder: 'Phone number',
            keyboardType: TextInputType.phone,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('+1'),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change Password'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: const [
              CupertinoTextField(
                placeholder: 'Current password',
                obscureText: true,
              ),
              SizedBox(height: 8),
              CupertinoTextField(
                placeholder: 'New password',
                obscureText: true,
              ),
              SizedBox(height: 8),
              CupertinoTextField(
                placeholder: 'Confirm new password',
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Password updated');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSetup2FADialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Set Up Two-Factor Authentication'),
        message: const Text('Choose a verification method'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('SMS setup coming soon');
            },
            child: const Text('SMS'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Authenticator setup coming soon');
            },
            child: const Text('Authenticator App'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            setState(() => _twoFactorEnabled = false);
          },
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showLogoutAllConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out of All Devices'),
        content: const Text(
          'You will be signed out of all devices including this one.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Sign Out All'),
          ),
        ],
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

class _SettingsDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsDetailRow({
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
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

class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _SettingsConnectedRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isConnected;
  final VoidCallback onTap;

  const _SettingsConnectedRow({
    required this.label,
    required this.icon,
    required this.isConnected,
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
              Icon(icon, size: 24, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.grey[200]
                      : const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
