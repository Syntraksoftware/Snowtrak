import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Unified like / comment / repost / share row — left-aligned (Threads-style).
class FeedActionBar extends StatefulWidget {
  const FeedActionBar({
    super.key,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.repostCount = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onRepost,
    this.showRepost = true,
    this.dense = false,
  });

  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int repostCount;
  final bool isLiked;
  final bool isReposted;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onRepost;
  final bool showRepost;
  final bool dense;

  @override
  State<FeedActionBar> createState() => _FeedActionBarState();
}

class _FeedActionBarState extends State<FeedActionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late bool _isLiked;

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
  void didUpdateWidget(FeedActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      _isLiked = widget.isLiked;
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() => _isLiked = !_isLiked);
    _likeAnimationController.forward(from: 0);
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.dense ? 20.0 : 24.0;
    final gap = widget.dense ? 16.0 : 20.0;
    final actions = <Widget>[
      _ActionSlot(
        icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        label: 'Like',
        count: widget.likeCount,
        isActive: _isLiked,
        iconSize: iconSize,
        onTap: widget.onLike != null ? _handleLike : null,
        animate: true,
        animation: _likeAnimationController,
      ),
      _ActionSlot(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Comment',
        count: widget.commentCount,
        iconSize: iconSize,
        onTap: widget.onComment,
      ),
      if (widget.showRepost)
        _ActionSlot(
          icon: Icons.repeat_rounded,
          label: 'Repost',
          count: widget.repostCount,
          isActive: widget.isReposted,
          iconSize: iconSize,
          onTap: widget.onRepost,
        ),
      _ActionSlot(
        icon: Icons.send_outlined,
        label: 'Share',
        count: widget.shareCount,
        iconSize: iconSize,
        onTap: widget.onShare,
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(top: widget.dense ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            actions[i],
          ],
        ],
      ),
    );
  }
}

class _ActionSlot extends StatelessWidget {
  const _ActionSlot({
    required this.icon,
    required this.label,
    this.count = 0,
    this.isActive = false,
    this.iconSize = 24,
    this.onTap,
    this.animate = false,
    this.animation,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final double iconSize;
  final VoidCallback? onTap;
  final bool animate;
  final AnimationController? animation;

  @override
  Widget build(BuildContext context) {
    const activeColor = SnowtrakColors.primary;
    const idleColor = SnowtrakColors.textSecondary;

    Widget iconWidget = Icon(
      icon,
      size: iconSize,
      color: isActive ? activeColor : idleColor,
    );

    if (animate && isActive && animation != null) {
      iconWidget = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.18).animate(
          CurvedAnimation(parent: animation!, curve: Curves.elasticOut),
        ),
        child: iconWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  _formatCount(count),
                  style: SnowtrakTypography.labelMedium.copyWith(
                    color: isActive ? activeColor : idleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
