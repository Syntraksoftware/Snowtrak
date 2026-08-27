import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

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
        Text(label, style: SnowtrakAuthTheme.fieldLabel(context)),
        const SizedBox(height: SnowtrakSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: SnowtrakTypography.bodyLarge.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: context.colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SnowtrakSpacing.md,
              vertical: SnowtrakSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide: BorderSide(color: context.colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SnowtrakAuthTheme.fieldRadius),
              borderSide:
                  BorderSide(color: context.colors.error, width: 1.5),
            ),
            hintStyle: SnowtrakTypography.bodyLarge.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
