import 'package:flutter/material.dart';
import 'package:syntrak/core/errors/app_error.dart';

class ThreadsTabFeedback {
  ThreadsTabFeedback._();

  static void showWaitForSync(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please wait for this post to finish syncing before $action.',
        ),
      ),
    );
  }

  static void showCouldNotSave(
    BuildContext context, {
    required String operation,
    required AppError error,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save $operation: ${error.userMessage}. '
          'Saved to retry automatically.',
        ),
      ),
    );
  }

  static void showCouldNotSend(
    BuildContext context, {
    required String operation,
    required AppError error,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not send $operation: ${error.userMessage}. '
          'Saved to retry automatically.',
        ),
      ),
    );
  }

  static void showCouldNotComplete(
    BuildContext context, {
    required String operation,
    required AppError error,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not $operation: ${error.userMessage}'),
      ),
    );
  }

  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}