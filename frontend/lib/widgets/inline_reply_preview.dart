import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/post.dart';

/// Threads-style reply teaser: stacked avatars + engagement summary.
class InlineReplyPreview extends StatelessWidget {
  const InlineReplyPreview({
    super.key,
    required this.replies,
    this.likeCount = 0,
    this.onTap,
  });

  final List<Post> replies;
  final int likeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    final previewReplies = replies.take(3).toList();
    final replyLabel = replies.length == 1
        ? '1 reply'
        : '${replies.length} replies';
    final likeLabel = likeCount == 1 ? '1 like' : '$likeCount likes';
    final summary = likeCount > 0 ? '$replyLabel · $likeLabel' : replyLabel;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            SizedBox(
              width: 18 + (previewReplies.length - 1) * 14.0,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < previewReplies.length; i++)
                    Positioned(
                      left: i * 14.0,
                      child: _MiniAvatar(author: previewReplies[i].author),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                summary,
                style: SnowtrakTypography.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.author});

  final PostAuthor author;

  @override
  Widget build(BuildContext context) {
    final initial = author.displayName.isNotEmpty
        ? author.displayName[0].toUpperCase()
        : '?';
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.surface,
        border: Border.all(color: context.colors.divider, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 9,
        backgroundColor: context.colors.primary.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: SnowtrakTypography.labelSmall.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
