import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Primary call-to-action with built-in loading state.
class LiquidButton extends StatelessWidget {
  const LiquidButton({
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
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
