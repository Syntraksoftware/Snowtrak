import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/post.dart';

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
        borderRadius: BorderRadius.circular(SyntrakRadius.md),
        border: Border.all(color: SyntrakColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: SyntrakColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: SyntrakTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SyntrakColors.primary,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.author.username,
                style: SyntrakTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SyntrakColors.textPrimary,
                ),
              ),
              Text(
                '  ·  ${post.timestampLabel}',
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textTertiary,
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
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
