import 'package:flutter/material.dart';

class GroupsIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const GroupsIcon({
    super.key,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.grey;

    return CustomPaint(
      size: Size(size, size),
      painter: _GroupsIconPainter(
        color: iconColor,
      ),
    );
  }
}

class _GroupsIconPainter extends CustomPainter {
  final Color color;

  _GroupsIconPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    // Draw three triangles forming a larger triangle
    // Top triangle
    final topPath = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * 0.75, size.height * 0.4)
      ..lineTo(size.width * 0.25, size.height * 0.4)
      ..close();
    canvas.drawPath(topPath, paint);

    // Bottom left triangle
    final bottomLeftPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom right triangle
    final bottomRightPath = Path()
      ..moveTo(size.width * 0.75, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

