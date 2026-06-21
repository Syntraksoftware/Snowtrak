import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/services/location_service.dart';

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
              color: SyntrakColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: SyntrakColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enable Location',
            style: SyntrakTypography.headlineMedium.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Syntrak uses your GPS to draw your route,\nmeasure distance, and calculate speed.',
            textAlign: TextAlign.center,
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final granted = await locationService.requestPermissions();
                if (context.mounted) Navigator.of(context).pop(granted);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SyntrakColors.primary,
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
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Not Now',
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
