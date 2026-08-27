import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/notification.dart';
import 'package:snowtrak/services/notification_service.dart';

/// Animated notification banner widget
class NotificationBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const NotificationBanner({super.key, 
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start animation
    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final typeColor = NotificationService.getColorForType(context, notification.type);
    final typeIcon = NotificationService.getIconForType(notification.type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx.abs() > 100) {
                _dismiss();
              }
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(SnowtrakSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
                  border: Border.all(
                    color: typeColor.withValues(alpha:0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon or Avatar
                    if (notification.avatarUrl != null)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(notification.avatarUrl!),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha:0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          typeIcon,
                          color: typeColor,
                          size: 22,
                        ),
                      ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.title,
                            style: SnowtrakTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.message,
                            style: SnowtrakTypography.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: context.colors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple toast message widget
class ToastMessage extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;
  final Duration duration;

  const ToastMessage({super.key, 
    required this.message,
    required this.onComplete,
    required this.duration,
  });

  @override
  State<ToastMessage> createState() => _ToastMessageState();
}

class _ToastMessageState extends State<ToastMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 40,
      right: 40,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: context.colors.textPrimary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(SnowtrakRadius.round),
              ),
              child: Text(
                widget.message,
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: context.colors.textOnPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
