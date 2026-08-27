import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

class CommunityHeader extends StatelessWidget {
  final VoidCallback? onHomeTap;
  final VoidCallback? onRefresh;
  final bool isAtTop;
  final bool isRefreshing;

  const CommunityHeader({
    super.key,
    this.onHomeTap,
    this.onRefresh,
    this.isAtTop = true,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Home logo
              GestureDetector(
                onTap: () {
                  if (isAtTop && isRefreshing == false) {
                    onRefresh?.call();
                  } else {
                    onHomeTap?.call();
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/logos/dark_logo.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.home,
                        size: 24,
                        color: context.colors.textPrimary,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Optional title
              Text(
                'Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const Spacer(),
              // Refresh indicator (when refreshing)
              if (isRefreshing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.colors.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
