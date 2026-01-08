import 'package:flutter/material.dart';

class MessageActions extends StatefulWidget {
  final int replyCount;
  final int likeCount;
  final int repostCount;
  final bool isLiked;
  final bool isReposted;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;

  const MessageActions({
    super.key,
    this.replyCount = 0,
    this.likeCount = 0,
    this.repostCount = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.onReply,
    this.onLike,
    this.onRepost,
    this.onShare,
  });

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    _likeAnimationController.forward(from: 0);
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Reply - left-aligned
        Flexible(
          child: _buildActionButton(
            icon: Icons.chat_bubble_outline,
            count: widget.replyCount,
            onTap: widget.onReply,
          ),
        ),
        const SizedBox(width: 16),
        // Like - consistent spacing
        Flexible(
          child: _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            count: widget.likeCount,
            isActive: _isLiked,
            onTap: _handleLike,
            animated: true,
          ),
        ),
        const SizedBox(width: 16),
        // Repost - consistent spacing
        Flexible(
          child: _buildActionButton(
            icon: Icons.repeat,
            count: widget.repostCount,
            isActive: widget.isReposted,
            onTap: widget.onRepost,
          ),
        ),
        const SizedBox(width: 16),
        // Share - consistent spacing
        Flexible(
          child: _buildActionButton(
            icon: Icons.share_outlined,
            onTap: widget.onShare,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int count = 0,
    bool isActive = false,
    VoidCallback? onTap,
    bool animated = false,
  }) {
    Widget iconWidget = Icon(
      icon,
      size: 20,
      color: isActive ? const Color(0xFFFF4500) : Colors.grey[600],
    );

    if (animated && isActive) {
      iconWidget = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(
            parent: _likeAnimationController,
            curve: Curves.elasticOut,
          ),
        ),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? const Color(0xFFFF4500) : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
