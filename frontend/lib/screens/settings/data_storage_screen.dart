import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
          'Data & Storage',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Storage
          _buildSectionHeader('STORAGE'),
          _SettingsGroup(
            children: [
              _StorageRow(label: 'Total App Storage', value: '124.5 MB'),
              _StorageRow(label: 'Cached Images', value: '45.2 MB'),
              _StorageRow(label: 'Offline Maps', value: '78.3 MB'),
            ],
          ),

          const SizedBox(height: 16),

          _SettingsGroup(
            children: [
              _SettingsActionRow(
                label: 'Clear Cache',
                subtitle: 'Free up 45.2 MB',
                isLoading: _isClearing,
                onTap: _clearCache,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Offline Maps
          _buildSectionHeader('OFFLINE MAPS'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                label: 'Download Maps',
                subtitle: 'Save for offline use',
                onTap: () => _showToast('Offline maps coming soon'),
              ),
              _SettingsNavigationRow(
                label: 'Manage Downloads',
                value: '2 maps',
                onTap: () => _showToast('Map management coming soon'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sync
          _buildSectionHeader('SYNC'),
          _SettingsGroup(
            children: [
              _SyncStatusRow(
                lastSynced: '5 minutes ago',
                onSync: _syncNow,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Your Data
          _buildSectionHeader('YOUR DATA'),
          _SettingsGroup(
            children: [
              _SettingsNavigationRow(
                label: 'Download My Data',
                subtitle: 'Get a copy of all your data',
                onTap: _showDownloadDataDialog,
              ),
              _SettingsNavigationRow(
                label: 'Export Activities',
                subtitle: 'GPX, TCX, or FIT',
                onTap: _showExportDialog,
              ),
            ],
          ),
          _buildSectionFooter(
            'Your data export will be sent to your email address.',
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

  Widget _buildSectionFooter(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      ),
    );
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isClearing = false);
      _showToast('Cache cleared');
    }
  }

  Future<void> _syncNow() async {
    _showToast('Syncing...');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _showToast('Sync complete');
  }

  void _showDownloadDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We\'ll prepare a copy of all your data and send it to your email.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Data export requested');
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Export Format'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Exporting as GPX...');
            },
            child: const Text('GPX (Universal)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Exporting as TCX...');
            },
            child: const Text('TCX (Training Center)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Exporting as FIT...');
            },
            child: const Text('FIT (Garmin)'),
          ),
        ],
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

class _StorageRow extends StatelessWidget {
  final String label;
  final String value;

  const _StorageRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 17, color: Colors.black)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 17, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _SettingsNavigationRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;

  const _SettingsNavigationRow({
    required this.label,
    this.subtitle,
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
              if (value != null)
                Text(value!,
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

class _SettingsActionRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.label,
    this.subtitle,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
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
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ),
              if (isLoading)
                const CupertinoActivityIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  final String lastSynced;
  final VoidCallback onSync;

  const _SyncStatusRow({required this.lastSynced, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last Synced',
                  style: TextStyle(fontSize: 17, color: Colors.black)),
              const SizedBox(height: 2),
              Text(lastSynced,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onSync,
            child: const Text(
              'Sync Now',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }
}
