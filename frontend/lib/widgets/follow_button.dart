import 'package:flutter/material.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/follow_stats.dart';
import 'package:snowtrak/services/follow_service.dart';

/// Follow / Following toggle, with the counts it already had to fetch.
///
/// Owns its own state: one `/follows/{id}/stats` call on mount, then an
/// optimistic flip on tap. Nothing above it needs to care.
class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    required this.userId,
    this.onChanged,
  });

  final String userId;

  /// Fires after a toggle settles, for anything that mirrors the counts.
  final ValueChanged<FollowStats>? onChanged;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final FollowService _followService = sl<FollowService>();

  FollowStats? _stats;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _loadStats();
  }

  Future<void> _loadStats() async {
    if (_failed) setState(() => _failed = false);

    final result = await _followService.getStats(widget.userId);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _stats = value;
          _failed = false;
        });
        widget.onChanged?.call(value);
      case AppFailure():
        // No counts rather than wrong counts. The slot keeps its size and
        // offers a retry.
        setState(() => _failed = true);
    }
  }

  Future<void> _toggle() async {
    final current = _stats;
    if (current == null || _busy) return;

    // Flip first: a follow that takes a round trip to acknowledge feels broken.
    setState(() {
      _stats = current.toggled();
      _busy = true;
    });

    final result = current.isFollowing
        ? await _followService.unfollow(widget.userId)
        : await _followService.follow(widget.userId);

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() => _busy = false);
        widget.onChanged?.call(_stats!);
      case AppFailure(:final error):
        setState(() {
          _stats = current;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    // The whole block keeps one shape in every state. It used to render
    // nothing until the stats landed, so the button popped into the card and
    // shoved the rest of the profile down a row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _countsRowHeight,
          child: stats == null ? const _CountsPlaceholder() : _counts(stats),
        ),
        const SizedBox(height: SnowtrakSpacing.sm),
        SizedBox(
          height: _buttonHeight,
          width: double.infinity,
          child: _action(stats),
        ),
      ],
    );
  }

  Widget _counts(FollowStats stats) {
    // Every child shrinks. Big numbers, long labels and the badge together
    // overrun a narrow phone otherwise, and the row has a fixed height so it
    // cannot wrap its way out.
    return Row(
      children: [
        Flexible(child: _CountLabel(value: stats.followerCount, label: 'followers')),
        const SizedBox(width: SnowtrakSpacing.md),
        Flexible(child: _CountLabel(value: stats.followingCount, label: 'following')),
        if (stats.isFollowedBy) ...[
          const SizedBox(width: SnowtrakSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SnowtrakSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: SnowtrakColors.surfaceVariant,
              borderRadius: BorderRadius.circular(SnowtrakRadius.round),
            ),
            child: Text(
              'Follows you',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SnowtrakTypography.labelSmall.copyWith(
                color: SnowtrakColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _action(FollowStats? stats) {
    if (stats == null) {
      // Failed rather than still loading: offer the way out instead of a grey
      // block that never resolves. We do not know the follow state, so we do
      // not guess at a label.
      if (_failed) {
        return OutlinedButton(
          onPressed: _loadStats,
          style: _outlinedStyle,
          child: const Text('Retry'),
        );
      }
      return const _ButtonPlaceholder();
    }

    if (stats.isFollowing) {
      return OutlinedButton(
        onPressed: _busy ? null : _toggle,
        style: _outlinedStyle,
        child: const Text('Following'),
      );
    }

    return FilledButton(
      onPressed: _busy ? null : _toggle,
      style: FilledButton.styleFrom(
        backgroundColor: SnowtrakColors.primary,
        foregroundColor: SnowtrakColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.md),
          side: const BorderSide(color: SnowtrakColors.ink),
        ),
      ),
      child: const Text('Follow'),
    );
  }

  ButtonStyle get _outlinedStyle => OutlinedButton.styleFrom(
        foregroundColor: SnowtrakColors.textPrimary,
        side: const BorderSide(color: SnowtrakColors.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        ),
      );
}

/// Reserved heights. Both states measure the same, which is the whole point.
const double _countsRowHeight = 22;
const double _buttonHeight = 44;

class _CountsPlaceholder extends StatelessWidget {
  const _CountsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _PlaceholderBar(width: 88),
        SizedBox(width: SnowtrakSpacing.md),
        _PlaceholderBar(width: 80),
      ],
    );
  }
}

class _ButtonPlaceholder extends StatelessWidget {
  const _ButtonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SnowtrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        // The fill alone is neutral100 on white -- almost invisible, so the
        // slot read as empty space rather than as a button on its way.
        border: Border.all(color: SnowtrakColors.borderStrong),
      ),
    );
  }
}

class _PlaceholderBar extends StatelessWidget {
  const _PlaceholderBar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: SnowtrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.xs),
        border: Border.all(color: SnowtrakColors.border),
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: SnowtrakTypography.bodyMedium.copyWith(
          color: SnowtrakColors.textSecondary,
        ),
        children: [
          TextSpan(
            text: '$value ',
            style: SnowtrakTypography.labelLarge.copyWith(
              color: SnowtrakColors.textPrimary,
            ),
          ),
          TextSpan(text: label),
        ],
      ),
    );
  }
}
