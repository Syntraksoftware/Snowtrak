import 'package:flutter/material.dart';
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
      barrierColor: Colors.black54,
      isDismissible: false,
      builder: (_) =>
          LocationPermissionDialog(locationService: locationService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5A1F).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFFF5A1F),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enable Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Syntrak uses your GPS to draw your route,\nmeasure distance, and calculate speed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
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
                backgroundColor: const Color(0xFFFF5A1F),
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
              child: const Text(
                'Not Now',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
