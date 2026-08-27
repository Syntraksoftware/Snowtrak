import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

// Reusable skeleton loading placeholders. Drop in wherever a CircularProgressIndicator
// was used during initial API fetch. One AnimationController per list via _SkeletonShimmer.

class SkeletonFeedList extends StatelessWidget {
  const SkeletonFeedList({super.key, this.itemCount = 4});
  final int itemCount;

  @override
  Widget build(BuildContext context) => _SkeletonShimmer(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (_, __) => const _SkeletonFeedCard(),
        ),
      );
}

class SkeletonNotificationList extends StatelessWidget {
  const SkeletonNotificationList({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) => _SkeletonShimmer(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (_, __) => const _SkeletonNotificationRow(),
        ),
      );
}

// -- Internal widgets --

class _SkeletonShimmer extends StatefulWidget {
  const _SkeletonShimmer({required this.child});
  final Widget child;

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Opacity(opacity: 0.4 + 0.55 * _ctrl.value, child: child),
        child: widget.child,
      );
}

class _SkeletonFeedCard extends StatelessWidget {
  const _SkeletonFeedCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            SnowtrakSpacing.md,
            SnowtrakSpacing.md,
            SnowtrakSpacing.sm,
            SnowtrakSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 36, height: 36, radius: 18),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 120),
                    SizedBox(height: 8),
                    _SkeletonBox(),
                    SizedBox(height: 4),
                    _SkeletonBox(),
                    SizedBox(height: 4),
                    _SkeletonBox(width: 200),
                    SizedBox(height: 12),
                    Row(children: [
                      _SkeletonBox(width: 40, height: 12),
                      SizedBox(width: 16),
                      _SkeletonBox(width: 40, height: 12),
                      SizedBox(width: 16),
                      _SkeletonBox(width: 40, height: 12),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.colors.divider),
      ],
    );
  }
}

class _SkeletonNotificationRow extends StatelessWidget {
  const _SkeletonNotificationRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.divider, width: 0.5),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 40, height: 40, radius: 20),
          SizedBox(width: SnowtrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: _SkeletonBox(height: 13)),
                  SizedBox(width: 40),
                  _SkeletonBox(width: 40, height: 11),
                ]),
                SizedBox(height: 6),
                _SkeletonBox(),
                SizedBox(height: 4),
                _SkeletonBox(width: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, this.height = 14, this.radius = 6});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
