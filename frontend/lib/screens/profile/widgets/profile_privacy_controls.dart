import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/settings/settings_screen.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

/// Interactive privacy toggles with visible switch styling (layout preview).
class ProfilePrivacyControls extends StatefulWidget {
  const ProfilePrivacyControls({super.key});

  @override
  State<ProfilePrivacyControls> createState() => _ProfilePrivacyControlsState();
}

class _ProfilePrivacyControlsState extends State<ProfilePrivacyControls> {
  bool _privacyZones = true;
  bool _mapVisibility = false;
  bool _profilePrivacy = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: SyntrakColors.surfaceVariant,
            borderRadius: BorderRadius.circular(SyntrakRadius.md),
            border: Border.all(color: SyntrakColors.divider),
          ),
          child: Column(
            children: [
              ProfilePrivacyToggleRow(
                icon: Icons.home_work_outlined,
                title: 'Privacy zones',
                subtitle: 'Hide start and end points near home or work',
                value: _privacyZones,
                onChanged: (v) => setState(() => _privacyZones = v),
                showDivider: true,
              ),
              ProfilePrivacyToggleRow(
                icon: Icons.map_outlined,
                title: 'Map visibility',
                subtitle: 'Hide maps, pace, or heart rate on public activities',
                value: _mapVisibility,
                onChanged: (v) => setState(() => _mapVisibility = v),
                showDivider: true,
              ),
              ProfilePrivacyToggleRow(
                icon: Icons.lock_person_outlined,
                title: 'Profile privacy',
                subtitle: 'Require approval before followers see activity maps',
                value: _profilePrivacy,
                onChanged: (v) => setState(() => _profilePrivacy = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: SyntrakSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Manage in settings'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SnowtrakAuthTheme.brand,
            side: const BorderSide(color: SnowtrakAuthTheme.brand),
            padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SyntrakRadius.round),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfilePrivacyToggleRow extends StatelessWidget {
  const ProfilePrivacyToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SyntrakSpacing.sm,
            vertical: SyntrakSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SnowtrakAuthTheme.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                ),
                child: Icon(icon, size: 18, color: SnowtrakAuthTheme.brand),
              ),
              const SizedBox(width: SyntrakSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SyntrakTypography.labelLarge.copyWith(
                        color: SyntrakColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: SyntrakTypography.bodySmall.copyWith(
                        color: SyntrakColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: SyntrakColors.textOnPrimary,
                activeTrackColor: SnowtrakAuthTheme.brand,
                inactiveThumbColor: SyntrakColors.surface,
                inactiveTrackColor: SyntrakColors.border,
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Divider(
              height: 1,
              thickness: 1,
              color: SyntrakColors.divider,
            ),
          ),
      ],
    );
  }
}
