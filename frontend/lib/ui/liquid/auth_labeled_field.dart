import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

/// Outlined field with a label stacked above the input.
class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SnowtrakAuthTheme.fieldLabel),
        const SizedBox(height: SyntrakSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: SyntrakTypography.bodyLarge.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: SyntrakColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SyntrakSpacing.md,
              vertical: SyntrakSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: const BorderSide(color: SnowtrakAuthTheme.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: const BorderSide(
                color: SnowtrakAuthTheme.brand,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: const BorderSide(color: SyntrakColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: const BorderSide(color: SyntrakColors.error, width: 1.5),
            ),
            hintStyle: SyntrakTypography.bodyLarge.copyWith(
              color: SyntrakColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
