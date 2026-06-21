import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: SnowtrakAuthTheme.brand,
          disabledBackgroundColor: SnowtrakAuthTheme.brandMuted.withValues(alpha: 0.35),
          foregroundColor: SyntrakColors.textOnPrimary,
          disabledForegroundColor: SyntrakColors.textOnPrimary.withValues(alpha: 0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnowtrakAuthTheme.buttonRadius),
          ),
          textStyle: SyntrakTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SyntrakColors.textOnPrimary,
                  ),
                ),
              )
            : Text(label),
      ),
    );
  }
}
