import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/widgets/quoted_post_embed.dart';
import 'package:syntrak/widgets/feed_action_bar.dart';
import 'package:syntrak/widgets/inline_reply_preview.dart';
import 'package:syntrak/widgets/post_media_gallery.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({
    super.key,
    required this.post,
    this.isExpanded = false,
    this.isReply = false,
    this.showInlineReplies = false,
    this.onTap,
    this.onAvatarTap,
    this.onLike,
    this.onRepost,
    this.onReply,
    this.onShare,
  });

  final Post post;
  final bool isExpanded;
  final bool isReply;
  final bool showInlineReplies;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final Function(Post post)? onLike;
  final Function(Post post)? onRepost;
  final Function(Post post)? onReply;
  final Function(Post post)? onShare;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  bool get _hasMedia =>
      widget.post.media != null && widget.post.media!.isNotEmpty;

  bool get _hasThreadPreview =>
      widget.showInlineReplies &&
      widget.post.replies != null &&
      widget.post.replies!.isNotEmpty;

  void _toggleExpand() {
    if (!widget.showInlineReplies) return;
    setState(() => _isExpanded = !_isExpanded);
    widget.onTap?.call();
  }

  void _onBodyTap() {
    if (widget.showInlineReplies) {
      _toggleExpand();
    } else {
      widget.onTap?.call();
    }
  }

  FeedActionBar _actionBar({bool dense = false}) {
    return FeedActionBar(
      dense: dense,
      likeCount: widget.post.likeCount,
      commentCount: widget.post.replyCount,
      shareCount: widget.post.shareCount,
      repostCount: widget.post.repostCount,
      isLiked: widget.post.likedByCurrentUser,
      isReposted: widget.post.repostedByCurrentUser,
      onLike: widget.onLike != null
          ? () => widget.onLike!(widget.post)
          : null,
      onComment: widget.onReply != null
          ? () => widget.onReply!(widget.post)
          : null,
      onRepost: widget.onRepost != null
          ? () => widget.onRepost!(widget.post)
          : null,
      onShare: widget.onShare != null
          ? () => widget.onShare!(widget.post)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReply) {
      return _ThreadReplyRow(
        post: widget.post,
        onTap: widget.onTap,
        actionBar: _actionBar(dense: true),
      );
    }

    return _ThreadsPostCard(
      post: widget.post,
      hasMedia: _hasMedia,
      isExpanded: _isExpanded,
      showInlineReplies: widget.showInlineReplies,
      onTap: widget.onTap != null || _hasThreadPreview ? _onBodyTap : null,
      onAvatarTap: widget.onAvatarTap,
      onToggleExpand: _toggleExpand,
      actionBar: _actionBar(),
      nestedReplies: _buildExpandedReplies(),
    );
  }

  List<Widget>? _buildExpandedReplies() {
    if (!_hasThreadPreview || !_isExpanded) return null;
    return widget.post.replies!.map((reply) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: MessageCard(
          post: reply,
          isReply: true,
          showInlineReplies: false,
          onLike: widget.onLike,
          onRepost: widget.onRepost,
          onReply: widget.onReply,
          onShare: widget.onShare,
        ),
      );
    }).toList();
  }
}

/// Single Threads-style layout for every post (text, media, or both).
class _ThreadsPostCard extends StatelessWidget {
  const _ThreadsPostCard({
    required this.post,
    required this.hasMedia,
    required this.isExpanded,
    required this.showInlineReplies,
    required this.actionBar,
    this.onTap,
    this.onAvatarTap,
    this.onToggleExpand,
    this.nestedReplies,
  });

  final Post post;
  final bool hasMedia;
  final bool isExpanded;
  final bool showInlineReplies;
  final FeedActionBar actionBar;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onToggleExpand;
  final List<Widget>? nestedReplies;

  bool get _hasReplies =>
      showInlineReplies && post.replies != null && post.replies!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.sm,
              SyntrakSpacing.sm,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AvatarColumn(
                    post: post,
                    showThreadLine: _hasReplies && !isExpanded,
                    onAvatarTap: onAvatarTap,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ThreadsMetaRow(post: post),
                        if (post.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _ThreadBodyText(text: post.text),
                        ],
                        if (hasMedia) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(SyntrakRadius.md),
                            child: PostMediaGallery(
                              urls: post.media!,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ],
                        if (post.quotedPost != null ||
                            post.quotedComment != null) ...[
                          const SizedBox(height: 10),
                          QuotedPostEmbed(
                            post: post.quotedPost ?? post.quotedComment!,
                          ),
                        ],
                        if (_hasReplies && !isExpanded) ...[
                          InlineReplyPreview(
                            replies: post.replies!,
                            likeCount: post.likeCount,
                            onTap: onToggleExpand,
                          ),
                        ],
                        if (nestedReplies != null) ...nestedReplies!,
                        actionBar,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: SyntrakColors.divider),
      ],
    );
  }
}

class _ThreadReplyRow extends StatelessWidget {
  const _ThreadReplyRow({
    required this.post,
    required this.actionBar,
    this.onTap,
  });

  final Post post;
  final FeedActionBar actionBar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasMedia = post.media != null && post.media!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAvatar(post: post, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThreadsMetaRow(post: post, compact: true),
                if (post.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _ThreadBodyText(text: post.text, compact: true),
                ],
                if (hasMedia) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                    child: PostMediaGallery(
                      urls: post.media!,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ],
                actionBar,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarColumn extends StatelessWidget {
  const _AvatarColumn({
    required this.post,
    required this.showThreadLine,
    this.onAvatarTap,
  });

  final Post post;
  final bool showThreadLine;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          _PostAvatar(post: post, onTap: onAvatarTap),
          if (showThreadLine)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.only(top: 6),
                color: SyntrakColors.divider,
              ),
            ),
        ],
      ),
    );
  }
}

class _PostAvatar extends StatelessWidget {
  const _PostAvatar({
    required this.post,
    this.radius = 22,
    this.onTap,
  });

  final Post post;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.displayName.isNotEmpty
        ? post.author.displayName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: SyntrakColors.primary.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: SyntrakTypography.labelMedium.copyWith(
            color: SyntrakColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.55,
          ),
        ),
      ),
    );
  }
}

class _ThreadsMetaRow extends StatelessWidget {
  const _ThreadsMetaRow({required this.post, this.compact = false});

  final Post post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  post.author.username,
                  style: (compact
                          ? SyntrakTypography.labelMedium
                          : SyntrakTypography.labelLarge)
                      .copyWith(
                    fontWeight: FontWeight.w700,
                    color: SyntrakColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '  ·  ',
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
              ),
              Text(
                post.timestampLabel,
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        if (!compact)
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: SyntrakColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _ThreadBodyText extends StatelessWidget {
  const _ThreadBodyText({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (compact
              ? SyntrakTypography.bodyMedium
              : SyntrakTypography.bodyLarge)
          .copyWith(
        color: SyntrakColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.1,
      ),
    );
  }
}
