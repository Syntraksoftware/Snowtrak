import 'package:flutter/material.dart';
import 'package:syntrak/models/post.dart';

/// Bordered preview of a post inside a quote (Threads-style).
class QuotedPostEmbed extends StatelessWidget {
  const QuotedPostEmbed({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.displayName.isNotEmpty
        ? post.author.displayName[0].toUpperCase()
        : 'U';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.author.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                post.timestampLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
