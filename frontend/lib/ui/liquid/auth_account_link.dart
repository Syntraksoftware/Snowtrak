import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

class AuthAccountLink extends StatelessWidget {
  const AuthAccountLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          style: SnowtrakAuthTheme.legalText.copyWith(fontSize: 14),
          children: [
            TextSpan(text: '$prompt '),
            TextSpan(
              text: actionLabel,
              style: const TextStyle(
                color: SnowtrakAuthTheme.brand,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()..onTap = onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
