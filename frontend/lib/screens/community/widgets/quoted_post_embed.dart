import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/post.dart';

/// Threads-style quoted post embed.
class QuotedPostEmbed extends StatelessWidget {
  const QuotedPostEmbed({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.displayName.isNotEmpty
        ? post.author.displayName[0].toUpperCase()
        : 'U';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
        border: Border.all(color: SnowtrakColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: SnowtrakColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: SnowtrakTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SnowtrakColors.primary,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.author.username,
                style: SnowtrakTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SnowtrakColors.textPrimary,
                ),
              ),
              Text(
                '  ·  ${post.timestampLabel}',
                style: SnowtrakTypography.bodySmall.copyWith(
                  color: SnowtrakColors.textTertiary,
                ),
              ),
            ],
          ),
          if (post.text.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: SnowtrakColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
