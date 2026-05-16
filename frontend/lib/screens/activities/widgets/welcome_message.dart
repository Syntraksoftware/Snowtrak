import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class WelcomeMessage extends StatelessWidget {
  const WelcomeMessage({
    super.key,
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
        SyntrakSpacing.md,
        SyntrakSpacing.lg,
      ),
      child: Text(
        'Welcome back, $username!',
        style: SyntrakTypography.displayMedium.copyWith(
          color: SyntrakColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
