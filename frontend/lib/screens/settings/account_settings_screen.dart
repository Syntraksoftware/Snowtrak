import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/settings/widgets/settings_account_widgets.dart';
import 'package:syntrak/screens/settings/widgets/settings_ios_widgets.dart';

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
          SettingsIosSectionHeader('CONTACT INFORMATION'),
          SettingsIosGroup(
            dividerLeadingPadding: 16,
            children: [
              SettingsAccountDetailRow(
                label: 'Email',
                value: email,
                trailing: _buildVerifiedBadge(),
                onTap: () => _showChangeEmailDialog(),
              ),
              SettingsAccountDetailRow(
                label: 'Phone',
                value: 'Not set',
                onTap: () => _showAddPhoneDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security
          SettingsIosSectionHeader('SECURITY'),
          SettingsIosGroup(
            dividerLeadingPadding: 16,
            children: [
              SettingsAccountNavigationRow(
                label: 'Change Password',
                onTap: () => _showChangePasswordDialog(),
              ),
              SettingsAccountToggleRow(
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
          SettingsIosSectionHeader('CONNECTED ACCOUNTS'),
          SettingsIosGroup(
            dividerLeadingPadding: 16,
            children: [
              SettingsAccountConnectedRow(
                label: 'Google',
                icon: Icons.g_mobiledata,
                isConnected: false,
                onTap: () => _showToast('Google connection coming soon'),
              ),
              SettingsAccountConnectedRow(
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
          SettingsIosSectionHeader('SESSIONS'),
          SettingsIosGroup(
            dividerLeadingPadding: 16,
            children: [
              SettingsAccountNavigationRow(
                label: 'Active Sessions',
                value: '1 device',
                onTap: () => _showToast('Active sessions coming soon'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SettingsIosGroup(
            dividerLeadingPadding: 16,
            children: [
              SettingsIosActionRow(
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
