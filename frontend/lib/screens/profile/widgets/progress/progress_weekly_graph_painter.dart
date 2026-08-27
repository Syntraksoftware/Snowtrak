import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Line chart for weekly distance buckets (12 weeks).
class ProgressWeeklyGraphPainter extends CustomPainter {
  ProgressWeeklyGraphPainter(
    this.weeks, {
    required this.lineColor,
    required this.gridColor,
  });

  final List<Map<String, dynamic>> weeks;

  /// A painter has no BuildContext, so the theme is read by the widget
  /// that builds it and handed over here.
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final distances = weeks.map((w) => w['count'] as double).toList();
    final maxDistance =
        distances.isEmpty ? 1.0 : distances.reduce((a, b) => a > b ? a : b);

    final stepX = weeks.length <= 1 ? 0.0 : size.width / (weeks.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < weeks.length; i++) {
      final distance = weeks[i]['count'] as double;
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
          ..color = lineColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(lastPoint, 6, highlightPaint);

        final linePaint = Paint()
          ..color = gridColor
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
  bool shouldRepaint(covariant ProgressWeeklyGraphPainter oldDelegate) =>
      oldDelegate.weeks != weeks ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}
