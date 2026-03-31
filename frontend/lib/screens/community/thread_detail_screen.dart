import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/community/community_post_mapper.dart';
import 'package:syntrak/services/community_service.dart';
import 'package:syntrak/widgets/message_actions.dart';

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
  final Future<void> Function(Post post, String text) onSubmitReply;
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

  Future<void> _reloadConversation() async {
    final current = _post;
    if (current == null) return;
    final result = await widget.communityService.getPostConversation(current.id);
    switch (result) {
      case AppSuccess(:final value):
        if (!mounted) return;
        setState(() {
          _post = current.copyWith(
            replies: CommunityPostMapper.mapRepliesFromComments(value),
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
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    await widget.onSubmitReply(current, text);
    _replyController.clear();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none, color: Colors.grey.shade700),
            tooltip: 'Coming soon',
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
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
                  onRepost: () => widget.onRepost(post),
                  onShare: () => widget.onShare(post),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Top',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.expand_more,
                              size: 20, color: Colors.grey.shade700),
                        ],
                      ),
                      Text(
                        'View activity ›',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                ...comments.map(
                  (comment) => _ThreadCommentItem(
                    post: comment,
                    onReplyTap: () => _handleReplyTo(comment),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Builder(
                    builder: (context) {
                      final me = _replyMeInitial(context);
                      return CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade300,
                        child: Text(
                          me,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              focusNode: _replyFocusNode,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submitReply(),
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                hintText: 'Add your reply...',
                                hintStyle: TextStyle(color: Colors.black45),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: null,
                            icon: Icon(Icons.image_outlined,
                                size: 22, color: Colors.grey.shade700),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: null,
                            icon: Icon(Icons.gif_box_outlined,
                                size: 22, color: Colors.grey.shade700),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: null,
                            icon: Icon(Icons.zoom_out_map_outlined,
                                size: 22, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _isSubmitting ? null : _submitReply,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _replyMeInitial(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return '?';
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      return user.firstName![0].toUpperCase();
    }
    return user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
  }
}

class _ThreadOriginalPostCard extends StatelessWidget {
  const _ThreadOriginalPostCard({
    required this.post,
    required this.onLike,
    required this.onRepost,
    required this.onShare,
  });

  final Post post;
  final VoidCallback onLike;
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
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Flexible(
                            child: Text(
                              '@${post.author.username}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
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
                        color: Colors.grey.shade500,
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
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 17,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: MessageActions(
            replyCount: post.replyCount,
            likeCount: post.likeCount,
            repostCount: post.repostCount,
            isLiked: post.likedByCurrentUser,
            isReposted: post.repostedByCurrentUser,
            onReply: () {},
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
  });

  final Post post;
  final VoidCallback onReplyTap;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.displayName.isNotEmpty
        ? post.author.displayName[0].toUpperCase()
        : 'U';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.timestampLabel,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.text,
                  style: const TextStyle(color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 4),
                MessageActions(
                  replyCount: post.replyCount,
                  likeCount: post.likeCount,
                  repostCount: post.repostCount,
                  isLiked: post.likedByCurrentUser,
                  isReposted: post.repostedByCurrentUser,
                  onReply: onReplyTap,
                  onLike: () {},
                  onRepost: () {},
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
