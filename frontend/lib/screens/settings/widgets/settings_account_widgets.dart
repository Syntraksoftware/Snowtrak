import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsAccountDetailRow extends StatelessWidget {
  const SettingsAccountDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

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

class SettingsAccountNavigationRow extends StatelessWidget {
  const SettingsAccountNavigationRow({
    super.key,
    required this.label,
    this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

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

class SettingsAccountToggleRow extends StatelessWidget {
  const SettingsAccountToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

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

class SettingsAccountConnectedRow extends StatelessWidget {
  const SettingsAccountConnectedRow({
    super.key,
    required this.label,
    required this.icon,
    required this.isConnected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isConnected;
  final VoidCallback onTap;

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
