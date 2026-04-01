import 'package:flutter/material.dart';

/// Threads-style repost / quote actions (keeps sheet UI out of [ThreadsTab]).
Future<void> showCommunityRepostSheet(
  BuildContext context, {
  required VoidCallback onDuplicateRepost,
  required VoidCallback onQuote,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _RepostSheetTile(
                label: 'Repost',
                icon: Icons.repeat,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDuplicateRepost();
                },
              ),
              const SizedBox(height: 10),
              _RepostSheetTile(
                label: 'Quote',
                icon: Icons.chat_bubble_outline,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onQuote();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RepostSheetTile extends StatelessWidget {
  const _RepostSheetTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F0F2),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(icon, color: Colors.black87, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
