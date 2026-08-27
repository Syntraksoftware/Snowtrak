import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/settings/settings_screen.dart';

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
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(SnowtrakRadius.md),
            border: Border.all(color: context.colors.divider),
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
        const SizedBox(height: SnowtrakSpacing.sm),
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
            foregroundColor: context.colors.primary,
            side: BorderSide(color: context.colors.primary),
            padding: const EdgeInsets.symmetric(vertical: SnowtrakSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnowtrakRadius.round),
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
            horizontal: SnowtrakSpacing.sm,
            vertical: SnowtrakSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                ),
                child: Icon(icon, size: 18, color: context.colors.primary),
              ),
              const SizedBox(width: SnowtrakSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SnowtrakTypography.labelLarge.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: SnowtrakTypography.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: context.colors.textOnPrimary,
                activeTrackColor: context.colors.primary,
                inactiveThumbColor: context.colors.surface,
                inactiveTrackColor: context.colors.border,
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
              color: context.colors.divider,
            ),
          ),
      ],
    );
  }
}
