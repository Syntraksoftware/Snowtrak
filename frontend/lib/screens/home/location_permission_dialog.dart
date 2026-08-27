import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/services/location_service.dart';

class LocationPermissionDialog extends StatelessWidget {
  final LocationService locationService;

  const LocationPermissionDialog({
    super.key,
    required this.locationService,
  });

  static Future<bool?> show(
      BuildContext context, LocationService locationService) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      isDismissible: false,
      builder: (_) =>
          LocationPermissionDialog(locationService: locationService),
    );
  }

  void _handlePermissionRequest(BuildContext context, bool granted) {
    Navigator.of(context).pop(granted);

    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We need your GPS service to record activities and show local weather. You can enable it later in Settings.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: SnowtrakColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SnowtrakColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: SnowtrakColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enable Location',
            style: SnowtrakTypography.headlineMedium.copyWith(
              color: SnowtrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Snowtrak uses your GPS to draw your route, measure distance, calculate speed, and show local weather conditions.',
            textAlign: TextAlign.center,
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: SnowtrakColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final granted = await locationService.requestPermissions();
                if (!context.mounted) return;
                _handlePermissionRequest(context, granted);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SnowtrakColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enable GPS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _handlePermissionRequest(context, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Not Now',
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: SnowtrakColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
