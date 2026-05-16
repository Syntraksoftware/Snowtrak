import 'package:flutter/material.dart';
import 'package:syntrak/models/location.dart';

/// Draws a polyline of [locations] into the canvas bounds (normalized lat/lng).
class ActivityRoutePreviewPainter extends CustomPainter {
  ActivityRoutePreviewPainter({
    required this.locations,
    required this.color,
  });

  final List<Location> locations;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final loc in locations) {
      minLat = minLat < loc.latitude ? minLat : loc.latitude;
      maxLat = maxLat > loc.latitude ? maxLat : loc.latitude;
      minLng = minLng < loc.longitude ? minLng : loc.longitude;
      maxLng = maxLng > loc.longitude ? maxLng : loc.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    if (latRange == 0 || lngRange == 0) return;

    var isFirst = true;
    for (final loc in locations) {
      final x = ((loc.longitude - minLng) / lngRange) * size.width;
      final y = size.height - ((loc.latitude - minLat) / latRange) * size.height;
      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ActivityRoutePreviewPainter oldDelegate) {
    return oldDelegate.locations != locations || oldDelegate.color != color;
  }
}
