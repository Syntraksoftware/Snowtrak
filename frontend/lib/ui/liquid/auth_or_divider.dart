import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
          child: Text(
            'or',
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.divider, height: 1)),
      ],
    );
  }
}
