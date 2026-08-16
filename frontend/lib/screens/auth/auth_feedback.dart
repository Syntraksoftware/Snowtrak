import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

void showAuthErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: SnowtrakColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
      ),
    ),
  );
}
