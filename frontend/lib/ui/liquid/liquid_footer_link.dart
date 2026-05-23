import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Inline prompt with a tappable action, e.g. "No account? Sign up".
class LiquidFooterLink extends StatelessWidget {
  const LiquidFooterLink({
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: SyntrakTypography.bodyMedium.copyWith(
            color: SyntrakColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
