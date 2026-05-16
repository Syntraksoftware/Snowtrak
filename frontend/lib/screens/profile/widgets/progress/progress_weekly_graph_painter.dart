import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Line chart for weekly distance buckets (12 weeks).
class ProgressWeeklyGraphPainter extends CustomPainter {
  ProgressWeeklyGraphPainter(this.weeks);

  final List<Map<String, dynamic>> weeks;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SyntrakColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = SyntrakColors.accent
      ..style = PaintingStyle.fill;

    final distances = weeks.map((w) => w['distance'] as double).toList();
    final maxDistance =
        distances.isEmpty ? 1.0 : distances.reduce((a, b) => a > b ? a : b);

    final stepX = weeks.length <= 1 ? 0.0 : size.width / (weeks.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < weeks.length; i++) {
      final distance = weeks[i]['distance'] as double;
      final normalizedDistance =
          maxDistance > 0 ? (distance / maxDistance) : 0.0;
      final y = size.height - (normalizedDistance * size.height);
      final x = weeks.length <= 1 ? size.width / 2 : i * stepX;

      if (x.isFinite && y.isFinite) {
        points.add(Offset(x, y));
      }
    }

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx.isFinite &&
          points[i].dy.isFinite &&
          points[i + 1].dx.isFinite &&
          points[i + 1].dy.isFinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    for (final point in points) {
      if (point.dx.isFinite && point.dy.isFinite) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }

    if (points.isNotEmpty) {
      final lastPoint = points.last;
      if (lastPoint.dx.isFinite && lastPoint.dy.isFinite) {
        final highlightPaint = Paint()
          ..color = SyntrakColors.accent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(lastPoint, 6, highlightPaint);

        final linePaint = Paint()
          ..color = SyntrakColors.textPrimary.withOpacity(0.3)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(lastPoint.dx, 0),
          Offset(lastPoint.dx, size.height),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
