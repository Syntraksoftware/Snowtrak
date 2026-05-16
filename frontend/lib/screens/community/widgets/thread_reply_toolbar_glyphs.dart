import 'package:flutter/material.dart';

/// Rounded-square landscape + sun (Threads-style photo picker glyph), light theme.
class ReplyToolbarPhotoGlyph extends StatelessWidget {
  const ReplyToolbarPhotoGlyph({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _ReplyToolbarPhotoGlyphPainter(color: color),
      ),
    );
  }
}

class _ReplyToolbarPhotoGlyphPainter extends CustomPainter {
  _ReplyToolbarPhotoGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const pad = 1.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad),
      const Radius.circular(5),
    );
    canvas.drawRRect(r, stroke);
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.30),
      size.shortestSide * 0.095,
      stroke,
    );
    final hill = Path()
      ..moveTo(size.width * 0.14, size.height * 0.71)
      ..lineTo(size.width * 0.36, size.height * 0.50)
      ..lineTo(size.width * 0.52, size.height * 0.60)
      ..lineTo(size.width * 0.86, size.height * 0.36)
      ..lineTo(size.width * 0.86, size.height * 0.71)
      ..lineTo(size.width * 0.14, size.height * 0.71);
    canvas.drawPath(hill, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReplyToolbarGifGlyph extends StatelessWidget {
  const ReplyToolbarGifGlyph({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color, width: 1.35),
        ),
        child: Center(
          child: Text(
            'GIF',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
