import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Minimal filled text field aligned with Syntrak theme tokens.
class LiquidTextField extends StatelessWidget {
  const LiquidTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: SyntrakTypography.bodyLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SyntrakTypography.bodyMedium.copyWith(
          color: SyntrakColors.textSecondary,
        ),
      ),
    );
  }
}
