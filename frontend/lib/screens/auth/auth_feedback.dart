import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

void showAuthErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: SyntrakColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.md),
      ),
    ),
  );
}
