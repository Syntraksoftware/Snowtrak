import 'package:flutter/material.dart';
import 'package:syntrak/services/location_service.dart';

class LocationPermissionDialog extends StatelessWidget {
  final LocationService locationService;

  const LocationPermissionDialog({
    super.key,
    required this.locationService,
  });

  static Future<bool?> show(
    BuildContext context,
    LocationService locationService,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          LocationPermissionDialog(locationService: locationService),
    );
  }

  void _handlePermissionRequest(
    BuildContext context,
    bool granted,
  ) {
    Navigator.of(context).pop(granted);

    if (!granted) {
      // Show message explaining why we need GPS.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We need your GPS service to record activities and show local weather. You can enable it later in Settings.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Location Access'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Syntrak needs access to your location to track your activities and show local weather conditions.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'We use your location to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('- Record your activity route'),
          Text('- Calculate distance and pace'),
          Text('- Show your route on the map'),
          Text('- Show local weather conditions'),
          SizedBox(height: 16),
          Text(
            'Your location data is only used for activity tracking and local weather, and is stored securely.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _handlePermissionRequest(context, false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () async {
            final granted = await locationService.requestPermissions();
            if (!context.mounted) return;
            _handlePermissionRequest(context, granted);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4500),
            foregroundColor: Colors.white,
          ),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
