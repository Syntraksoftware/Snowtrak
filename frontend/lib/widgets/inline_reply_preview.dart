import 'package:flutter/material.dart';
import 'package:syntrak/models/post.dart';

class InlineReplyPreview extends StatelessWidget {
  final List<Post> replies;
  final VoidCallback? onTap;

  const InlineReplyPreview({
    super.key,
    required this.replies,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    // Show up to 2 latest replies
    final previewReplies = replies.take(2).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8, left: 40),
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...previewReplies.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey[300],
                        child: reply.author.avatarUrl != null
                            ? null
                            : Text(
                                reply.author.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reply.author.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '@${reply.author.username}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reply.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (replies.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${replies.length - 2} more replies',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
