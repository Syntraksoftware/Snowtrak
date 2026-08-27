import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/screens/community/community_post_mapper.dart';
import 'package:snowtrak/screens/community/thread_media_upload.dart';
import 'package:snowtrak/screens/community/widgets/thread_media_attachments_bar.dart';
import 'package:snowtrak/screens/community/widgets/thread_expanded_reply_sheet.dart';
import 'package:snowtrak/screens/community/widgets/thread_reply_composer_bar.dart';
import 'package:snowtrak/screens/profile/user_profile_screen.dart';
import 'package:snowtrak/services/community_service.dart';
import 'package:snowtrak/screens/community/widgets/quoted_post_embed.dart';
import 'package:snowtrak/widgets/message_actions.dart';
import 'package:snowtrak/widgets/post_media_gallery.dart';

class ThreadDetailScreen extends StatefulWidget {
  const ThreadDetailScreen({
    super.key,
    required this.post,
    required this.communityService,
    required this.onSubmitReply,
    required this.onLike,
    required this.onRepost,
    required this.onShare,
  });

  final Post post;
  final CommunityService communityService;
  final Future<void> Function(Post post, String text, List<String> mediaUrls)
      onSubmitReply;
  final void Function(Post post) onLike;
  final void Function(Post post) onRepost;
  final void Function(Post post) onShare;

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _isSubmitting = false;
  Post? _post;
  final List<XFile> _replyMedia = [];

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _reloadConversation();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _handleReplyTo(Post target) {
    final mention = '@${target.author.username} ';
    final current = _replyController.text;
    if (!current.startsWith(mention)) {
      _replyController.text = '$mention$current'.trimRight();
      _replyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _replyController.text.length),
      );
    }
    _replyFocusNode.requestFocus();
  }

  void _pickReplyImages() {
    pickThreadImages(
      _replyMedia,
      (next) => setState(() {
        _replyMedia
          ..clear()
          ..addAll(next);
      }),
    );
  }

  void _showExpandedReplySheet() {
    showThreadExpandedReplySheet(
      context: context,
      controller: _replyController,
      media: _replyMedia,
      isSubmitting: _isSubmitting,
      onAddImages: _pickReplyImages,
      onSubmit: _submitReply,
      onRemove: (i) => setState(() {
        _replyMedia.removeAt(i);
      }),
      onSetMedia: (next) => setState(() {
        _replyMedia
          ..clear()
          ..addAll(next);
      }),
    );
  }

  Future<void> _reloadConversation() async {
    final current = _post;
    if (current == null) return;
    final result = await widget.communityService.getPostConversation(current.id);
    switch (result) {
      case AppSuccess(:final value):
        if (!mounted) return;
        setState(() {
          _post = current.copyWith(
            replies: CommunityPostMapper.mapRepliesFromComments(
              value,
              threadSubthreadId: current.subthreadId,
              parentPostId: current.id,
            ),
            replyCount: value.where((c) => c['parent_id'] == null).length,
          );
        });
      case AppFailure():
        break;
    }
  }

  Future<void> _submitReply() async {
    if (_isSubmitting) return;
    final current = _post;
    if (current == null) return;
    final text = _replyController.text.trim();
    if (text.isEmpty && _replyMedia.isEmpty) {
      return;
    }
    setState(() => _isSubmitting = true);
    var mediaUrls = <String>[];
    if (_replyMedia.isNotEmpty) {
      final uploaded = await uploadThreadMediaFiles(
        widget.communityService,
        _replyMedia,
      );
      switch (uploaded) {
        case AppSuccess(:final value):
          mediaUrls = value;
        case AppFailure(:final error):
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.userMessage)),
            );
          }
          return;
      }
    }
    await widget.onSubmitReply(current, text, mediaUrls);
    _replyController.clear();
    setState(() => _replyMedia.clear());
    await _reloadConversation();
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final comments = List<Post>.from(post.replies ?? const <Post>[]);
    final subtitle = post.replyCount > 0
        ? '${post.replyCount} repl${post.replyCount == 1 ? 'y' : 'ies'}'
        : 'No replies yet';
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thread',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none, color: context.colors.textSecondary),
            tooltip: 'Coming soon',
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz, color: context.colors.textSecondary),
            tooltip: 'Coming soon',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _ThreadOriginalPostCard(
                  post: post,
                  onLike: () => widget.onLike(post),
                  onReplyTap: () => _replyFocusNode.requestFocus(),
                  onRepost: () => widget.onRepost(post),
                  onShare: () => widget.onShare(post),
                ),
                Divider(height: 1, thickness: 1, color: context.colors.surfaceVariant),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Top',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.expand_more,
                              size: 20, color: context.colors.textSecondary),
                        ],
                      ),
                      Text(
                        'View activity ›',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: context.colors.surfaceVariant),
                ...comments.map(
                  (comment) => _ThreadCommentItem(
                    post: comment,
                    onReplyTap: () => _handleReplyTo(comment),
                    onRepost: () => widget.onRepost(comment),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: ThreadReplyComposerBar(
              replyMedia: _replyMedia,
              controller: _replyController,
              focusNode: _replyFocusNode,
              onRemoveMedia: (i) => setState(() {
                _replyMedia.removeAt(i);
              }),
              onSubmit: _submitReply,
              onPickImages: _pickReplyImages,
              onExpand: _showExpandedReplySheet,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadOriginalPostCard extends StatelessWidget {
  const _ThreadOriginalPostCard({
    required this.post,
    required this.onLike,
    required this.onReplyTap,
    required this.onRepost,
    required this.onShare,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onReplyTap;
  final VoidCallback onRepost;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.displayName.isNotEmpty
        ? post.author.displayName[0].toUpperCase()
        : 'U';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => openUserProfile(
              context,
              post.author.id,
              displayName: post.author.displayName,
              username: post.author.username,
            ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: context.colors.divider,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Text(
                            post.author.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(color: context.colors.textTertiary),
                          ),
                          Flexible(
                            child: Text(
                              (post.topic ?? '').trim().isNotEmpty
                                  ? post.topic!.trim()
                                  : '@${post.author.username}',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      post.timestampLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              post.text,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 17,
                height: 1.35,
              ),
            ),
          ),
          if (post.media != null && post.media!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: PostMediaGallery(urls: post.media!),
            ),
          ],
          if (post.quotedPost != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: QuotedPostEmbed(post: post.quotedPost!),
            ),
          ],
          if (post.quotedComment != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: QuotedPostEmbed(post: post.quotedComment!),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: MessageActions(
              replyCount: post.replyCount,
              likeCount: post.likeCount,
              repostCount: post.repostCount,
              shareCount: post.shareCount,
              isLiked: post.likedByCurrentUser,
              isReposted: post.repostedByCurrentUser,
              onReply: onReplyTap,
              onLike: onLike,
              onRepost: onRepost,
              onShare: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadCommentItem extends StatelessWidget {
  const _ThreadCommentItem({
    required this.post,
    required this.onReplyTap,
    required this.onRepost,
  });

  final Post post;
  final VoidCallback onReplyTap;
  final VoidCallback onRepost;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.displayName.isNotEmpty
        ? post.author.displayName[0].toUpperCase()
        : 'U';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.surfaceVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openUserProfile(
              context,
              post.author.id,
              displayName: post.author.displayName,
              username: post.author.username,
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.divider,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.author.displayName,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.timestampLabel,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.text,
                  style: TextStyle(color: context.colors.textPrimary, height: 1.3),
                ),
                if (post.media != null && post.media!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  PostMediaGallery(urls: post.media!),
                ],
                const SizedBox(height: 4),
                MessageActions(
                  replyCount: post.replyCount,
                  likeCount: post.likeCount,
                  repostCount: post.repostCount,
                  shareCount: post.shareCount,
                  isLiked: post.likedByCurrentUser,
                  isReposted: post.repostedByCurrentUser,
                  onReply: onReplyTap,
                  onLike: () {},
                  onRepost: onRepost,
                  onShare: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
