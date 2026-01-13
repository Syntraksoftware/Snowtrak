import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  bool _isClearing = false;

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
        title: const Text('Data & Storage'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: SyntrakSpacing.lg),

          // Storage Section
          _buildSectionHeader('Storage'),
          _SettingsGroup(
            children: [
              _StorageInfoRow(
                icon: Icons.folder_outlined,
                label: 'Total app storage',
                value: '124.5 MB',
              ),
              _StorageInfoRow(
                icon: Icons.image_outlined,
                label: 'Cached images',
                value: '45.2 MB',
              ),
              _StorageInfoRow(
                icon: Icons.map_outlined,
                label: 'Offline maps',
                value: '78.3 MB',
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsActionRow(
                icon: Icons.cleaning_services_outlined,
                label: 'Clear cache',
                subtitle: 'Free up 45.2 MB',
                isLoading: _isClearing,
                onTap: () => _clearCache(),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Offline Maps Section
          _buildSectionHeader('Offline Maps'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.download_outlined,
                label: 'Download maps',
                subtitle: 'Save resort maps for offline use',
                onTap: () => _showToast('Offline maps coming soon'),
              ),
              _SettingsNavigationRow(
                icon: Icons.folder_delete_outlined,
                label: 'Manage downloads',
                subtitle: '2 maps downloaded',
                onTap: () => _showToast('Map management coming soon'),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Sync Section
          _buildSectionHeader('Sync'),
          _SettingsGroup(
            children: [
              _SyncStatusRow(
                lastSynced: DateTime.now().subtract(const Duration(minutes: 5)),
                onSync: () => _syncNow(),
              ),
            ],
          ),

          const SizedBox(height: SyntrakSpacing.lg),

          // Export Section
          _buildSectionHeader('Your Data'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                icon: Icons.download_for_offline_outlined,
                label: 'Download my data',
                subtitle: 'Get a copy of all your data',
                onTap: () => _showDownloadDataDialog(),
              ),
              _SettingsNavigationRow(
                icon: Icons.import_export,
                label: 'Export activities',
                subtitle: 'Export to GPX, TCX, or FIT',
                onTap: () => _showExportDialog(),
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

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isClearing = false);
    if (mounted) {
      _showToast('Cache cleared successfully');
    }
  }

  Future<void> _syncNow() async {
    _showToast('Syncing...');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _showToast('Sync complete');
    }
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We\'ll prepare a copy of all your data including activities, profile information, and settings. You\'ll receive an email when it\'s ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Data export requested. Check your email soon.');
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
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
              'Export Format',
              style: SyntrakTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text('GPX'),
              subtitle: const Text('Universal GPS format'),
              onTap: () {
                Navigator.pop(context);
                _showToast('Exporting as GPX...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text('TCX'),
              subtitle: const Text('Training Center format'),
              onTap: () {
                Navigator.pop(context);
                _showToast('Exporting as TCX...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text('FIT'),
              subtitle: const Text('Garmin format'),
              onTap: () {
                Navigator.pop(context);
                _showToast('Exporting as FIT...');
              },
            ),
            const SizedBox(height: SyntrakSpacing.lg),
          ],
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

class _StorageInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StorageInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            style: SyntrakTypography.bodyMedium
                .copyWith(color: SyntrakColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
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
                color: SyntrakColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: SyntrakColors.primary),
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
                      color: SyntrakColors.primary,
                    ),
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
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
                ),
              ),
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

class _SyncStatusRow extends StatelessWidget {
  final DateTime lastSynced;
  final VoidCallback onSync;

  const _SyncStatusRow({
    required this.lastSynced,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final difference = DateTime.now().difference(lastSynced);
    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours} hours ago';
    } else {
      timeAgo = '${difference.inDays} days ago';
    }

    return Padding(
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
            child: Icon(Icons.sync,
                size: 20, color: SyntrakColors.textSecondary),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last synced',
                  style: SyntrakTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: SyntrakTypography.bodySmall
                      .copyWith(color: SyntrakColors.textTertiary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSync,
            child: Text(
              'Sync Now',
              style: TextStyle(color: SyntrakColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
