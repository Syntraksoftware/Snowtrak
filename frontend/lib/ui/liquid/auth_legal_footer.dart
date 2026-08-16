import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
  return Text.rich(
      TextSpan(
        style: SnowtrakAuthTheme.legalText,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: SnowtrakAuthTheme.legalText.copyWith(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO: open Terms of Service
              },
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: SnowtrakAuthTheme.legalText.copyWith(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO: open Privacy Policy
              },
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
