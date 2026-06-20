import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: SyntrakColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
          child: Text(
            'or',
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: SyntrakColors.divider, height: 1)),
      ],
    );
  }
}
