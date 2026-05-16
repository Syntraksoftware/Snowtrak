import 'package:flutter/material.dart';

/// Returns trimmed reply text, or null if cancelled / empty.
Future<String?> showThreadReplyDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Reply'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Reply'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  final text = (result ?? '').trim();
  return text.isEmpty ? null : text;
}
