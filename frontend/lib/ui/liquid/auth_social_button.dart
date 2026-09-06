import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

enum AuthSocialProvider { google, apple }

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final AuthSocialProvider provider;
  final VoidCallback onPressed;

  String get _label => switch (provider) {
        AuthSocialProvider.google => 'Continue with Google',
        AuthSocialProvider.apple => 'Continue with Apple',
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.textPrimary,
          side: BorderSide(color: context.colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnowtrakAuthTheme.buttonRadius),
          ),
          textStyle: SnowtrakTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderIcon(provider: provider),
            const SizedBox(width: SnowtrakSpacing.sm),
            Text(_label),
          ],
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider});

  final AuthSocialProvider provider;

  @override
  Widget build(BuildContext context) {
    return switch (provider) {
      AuthSocialProvider.google => const _GoogleMark(),
      AuthSocialProvider.apple => const Icon(Icons.apple, size: 22),
    };
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.6,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.2,
      1.0,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.2,
      1.0,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.2,
      1.0,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      Offset(size.width * 0.95, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
