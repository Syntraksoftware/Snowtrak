import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/notification.dart';

/// Service for displaying in-app notifications (SnackBars, Banners, Overlays)
/// 
/// Usage:
/// ```dart
/// // Show a success message
/// NotificationService.showSuccess(context, 'Activity saved!');
/// 
/// // Show an error message  
/// NotificationService.showError(context, 'Failed to save');
/// 
/// // Show a custom notification banner
/// NotificationService.showBanner(
///   context,
///   notification: AppNotification(...),
///   onTap: () => Navigator.push(...),
/// );
/// ```
class NotificationService {
  // Private constructor to prevent instantiation
  NotificationService._();

  /// Show a success SnackBar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: SnowtrakColors.success,
      icon: Icons.check_circle_outline,
      duration: duration,
      action: action,
    );
  }

  /// Show an error SnackBar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: SnowtrakColors.error,
      icon: Icons.error_outline,
      duration: duration,
      action: action,
    );
  }

  /// Show an info SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: SnowtrakColors.info,
      icon: Icons.info_outline,
      duration: duration,
      action: action,
    );
  }

  /// Show a warning SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: SnowtrakColors.warning,
      icon: Icons.warning_amber_outlined,
      duration: duration,
      action: action,
    );
  }

  /// Show a custom styled SnackBar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Hide any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: context.colors.textOnPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.colors.textOnPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
      ),
      margin: const EdgeInsets.all(SnowtrakSpacing.md),
      duration: duration,
      action: action,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show a notification banner at the top of the screen
  /// This is useful for social notifications that the user should notice
  static void showBanner(
    BuildContext context, {
    required AppNotification notification,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationBanner(
        notification: notification,
        onTap: () {
          overlayEntry.remove();
          onTap?.call();
        },
        onDismiss: () {
          overlayEntry.remove();
          onDismiss?.call();
        },
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Show a simple toast-like message at the bottom
  static void showToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastMessage(
        message: message,
        onComplete: () => overlayEntry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Get icon for notification type
  static IconData getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.kudos:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.follow:
        return Icons.person_add_outlined;
      case NotificationType.friendActivity:
        return Icons.directions_run;
      case NotificationType.challenge:
        return Icons.emoji_events_outlined;
      case NotificationType.group:
        return Icons.group_outlined;
      case NotificationType.weather:
        return Icons.cloud_outlined;
      case NotificationType.powderDay:
        return Icons.ac_unit;
      case NotificationType.achievement:
        return Icons.military_tech_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  /// Get color for notification type
  static Color getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.kudos:
        return SnowtrakColors.notifyKudos;
      case NotificationType.comment:
        return SnowtrakColors.primary;
      case NotificationType.follow:
        return SnowtrakColors.secondary;
      case NotificationType.friendActivity:
        return SnowtrakColors.accent;
      case NotificationType.challenge:
        return SnowtrakColors.notifyChallenge;
      case NotificationType.group:
        return SnowtrakColors.info;
      case NotificationType.weather:
        return SnowtrakColors.notifyWeather;
      case NotificationType.powderDay:
        return SnowtrakColors.notifyPowderDay;
      case NotificationType.achievement:
        return SnowtrakColors.notifyChallenge;
      case NotificationType.system:
        return SnowtrakColors.textSecondary;
    }
  }
}

/// Animated notification banner widget
class _NotificationBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const _NotificationBanner({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
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
    final typeColor = NotificationService.getColorForType(notification.type);
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
                    color: typeColor.withOpacity(0.3),
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
                          color: typeColor.withOpacity(0.15),
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
                              color: SnowtrakColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.message,
                            style: SnowtrakTypography.bodySmall.copyWith(
                              color: SnowtrakColors.textSecondary,
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
                      color: SnowtrakColors.textTertiary,
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
class _ToastMessage extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;
  final Duration duration;

  const _ToastMessage({
    required this.message,
    required this.onComplete,
    required this.duration,
  });

  @override
  State<_ToastMessage> createState() => _ToastMessageState();
}

class _ToastMessageState extends State<_ToastMessage>
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
                color: SnowtrakColors.textPrimary.withOpacity(0.9),
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
