import 'package:flutter/material.dart';
import 'package:syntrak/widgets/feed_action_bar.dart';

/// Back-compat wrapper — community cards use [FeedActionBar] directly.
class MessageActions extends StatelessWidget {
  const MessageActions({
    super.key,
    this.replyCount = 0,
    this.likeCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.onReply,
    this.onLike,
    this.onRepost,
    this.onShare,
  });

  final int replyCount;
  final int likeCount;
  final int repostCount;
  final int shareCount;
  final bool isLiked;
  final bool isReposted;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return FeedActionBar(
      likeCount: likeCount,
      commentCount: replyCount,
      shareCount: shareCount,
      repostCount: repostCount,
      isLiked: isLiked,
      isReposted: isReposted,
      onLike: onLike,
      onComment: onReply,
      onRepost: onRepost,
      onShare: onShare,
    );
  }
}
