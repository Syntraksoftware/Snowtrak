import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/widgets/compact_composer.dart';
import 'package:snowtrak/widgets/message_card.dart';

class ThreadsEmptyState extends StatelessWidget {
  const ThreadsEmptyState({
    super.key,
    required this.message,
    required this.retryable,
    required this.onRetry,
  });

  final String message;
  final bool retryable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SnowtrakSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: SnowtrakColors.error,
              ),
            ),
            if (retryable) ...[
              const SizedBox(height: SnowtrakSpacing.md),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ThreadsFeedBody extends StatelessWidget {
  const ThreadsFeedBody({
    super.key,
    required this.posts,
    required this.onRefresh,
    required this.onComposerSubmit,
    required this.onComposeTap,
    required this.onPostTap,
    required this.onLike,
    required this.onRepost,
    required this.onReply,
    required this.onShare,
  });

  final List<Post> posts;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String text) onComposerSubmit;
  final VoidCallback onComposeTap;
  final void Function(Post post) onPostTap;
  final void Function(Post post) onLike;
  final void Function(Post post) onRepost;
  final void Function(Post post) onReply;
  final void Function(Post post) onShare;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: SnowtrakColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: SnowtrakSpacing.md),
        itemCount: posts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return CompactComposer(
              onPost: onComposerSubmit,
              maxCharacters: 280,
              onComposeTap: onComposeTap,
            );
          }
          final post = posts[index - 1];
          return MessageCard(
            post: post,
            onTap: () => onPostTap(post),
            onLike: onLike,
            onRepost: onRepost,
            onReply: onReply,
            onShare: onShare,
          );
        },
      ),
    );
  }
}
