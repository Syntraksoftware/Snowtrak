import 'package:flutter/material.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/widgets/message_actions.dart';
import 'package:syntrak/widgets/inline_reply_preview.dart';

class MessageCard extends StatefulWidget {
  final Post post;
  final bool isExpanded;
  final bool isReply; // Indicates if this is a nested reply
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final Function(Post post)? onLike;
  final Function(Post post)? onRepost;
  final Function(Post post)? onReply;
  final Function(Post post)? onShare;

  const MessageCard({
    super.key,
    required this.post,
    this.isExpanded = false,
    this.isReply = false,
    this.onTap,
    this.onAvatarTap,
    this.onLike,
    this.onRepost,
    this.onReply,
    this.onShare,
  });

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

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16, // Same padding for all - ensures alignment
        vertical: widget.isReply ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: widget.isReply
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar, name, handle, timestamp - all horizontally aligned
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: widget.onAvatarTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.post.author.avatarUrl != null
                      ? null // TODO: Add NetworkImage support
                      : null,
                  child: widget.post.author.avatarUrl == null
                      ? Text(
                          widget.post.author.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Name, handle, timestamp - all on same baseline
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Text(
                            widget.post.author.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '·',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '@${widget.post.author.username}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.timestampLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(
                left:
                    52), // Align with name/handle (avatar 40px + spacing 12px)
            child: GestureDetector(
              onTap: _toggleExpand,
              child: Text(
                widget.post.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Optional media
          if (widget.post.media != null && widget.post.media!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Inline reply preview (if not expanded and has replies)
          if (!_isExpanded &&
              widget.post.replies != null &&
              widget.post.replies!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InlineReplyPreview(
              replies: widget.post.replies!,
              onTap: _toggleExpand,
            ),
          ],
          // Expanded replies (if expanded)
          if (_isExpanded &&
              widget.post.replies != null &&
              widget.post.replies!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              margin: EdgeInsets.zero, // Start at same position as main post
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.zero,
              child: Column(
                children: widget.post.replies!.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MessageCard(
                      post: reply,
                      isReply: true,
                      onLike: widget.onLike,
                      onRepost: widget.onRepost,
                      onReply: widget.onReply,
                      onShare: widget.onShare,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),

          MessageActions(
            replyCount: widget.post.replyCount,
            likeCount: widget.post.likeCount,
            repostCount: widget.post.repostCount,
            isLiked: widget.post.likedByCurrentUser,
            isReposted: widget.post.repostedByCurrentUser,
            onReply: () => widget.onReply?.call(widget.post),
            onLike: () => widget.onLike?.call(widget.post),
            onRepost: () => widget.onRepost?.call(widget.post),
            onShare: () => widget.onShare?.call(widget.post),
          ),
        ],
      ),
    );
  }
}
