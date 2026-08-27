import 'package:flutter/material.dart';
import 'package:snowtrak/widgets/notification_overlays.dart';
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
      backgroundColor: context.colors.success,
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
      backgroundColor: context.colors.error,
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
      backgroundColor: context.colors.info,
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
      backgroundColor: context.colors.warning,
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
      builder: (context) => NotificationBanner(
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
      builder: (context) => ToastMessage(
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
  static Color getColorForType(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.kudos:
        return SnowtrakColors.notifyKudos;
      case NotificationType.comment:
        return context.colors.primary;
      case NotificationType.follow:
        return SnowtrakColors.secondary;
      case NotificationType.friendActivity:
        return SnowtrakColors.accent;
      case NotificationType.challenge:
        return SnowtrakColors.notifyChallenge;
      case NotificationType.group:
        return context.colors.info;
      case NotificationType.weather:
        return SnowtrakColors.notifyWeather;
      case NotificationType.powderDay:
        return SnowtrakColors.notifyPowderDay;
      case NotificationType.achievement:
        return SnowtrakColors.notifyChallenge;
      case NotificationType.system:
        return context.colors.textSecondary;
    }
  }
}
