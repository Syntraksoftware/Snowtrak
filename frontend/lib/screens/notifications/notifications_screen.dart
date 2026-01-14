import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/notification.dart';
import 'package:syntrak/providers/notification_provider.dart';
import 'package:syntrak/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        backgroundColor: SyntrakColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.hasUnread) {
                return TextButton(
                  onPressed: () {
                    provider.markAllAsRead();
                    NotificationService.showSuccess(
                      context,
                      'All notifications marked as read',
                    );
                  },
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: SyntrakColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationList(provider);
        },
      ),
    );
  }

  Widget _buildNotificationList(NotificationProvider provider) {
    final grouped = provider.groupedNotifications;
    final sections = ['Today', 'Yesterday', 'This Week', 'Earlier'];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.md),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final notifications = grouped[section];

        if (notifications == null || notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.md,
                vertical: SyntrakSpacing.sm,
              ),
              child: Text(
                section,
                style: SyntrakTypography.labelMedium.copyWith(
                  color: SyntrakColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Notification items
            ...notifications.map((notification) => _NotificationItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismiss: () => _handleNotificationDismiss(notification),
                )),
            const SizedBox(height: SyntrakSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SyntrakSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SyntrakColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: SyntrakColors.textTertiary,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.lg),
            Text(
              'No Notifications',
              style: SyntrakTypography.headlineSmall.copyWith(
                color: SyntrakColors.textPrimary,
              ),
            ),
            const SizedBox(height: SyntrakSpacing.sm),
            Text(
              'When you get notifications, they\'ll show up here',
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SyntrakSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: SyntrakColors.error,
            ),
            const SizedBox(height: SyntrakSpacing.md),
            Text(
              provider.error ?? 'Something went wrong',
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SyntrakSpacing.lg),
            ElevatedButton(
              onPressed: () => provider.loadNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    context.read<NotificationProvider>().markAsRead(notification.id);

    // Navigate based on notification type (example)
    if (notification.actionRoute != null) {
      // Navigate to specific route
      // Navigator.pushNamed(context, notification.actionRoute!);
    }

    // For now, show a toast
    NotificationService.showToast(context, 'Tapped: ${notification.title}');
  }

  void _handleNotificationDismiss(AppNotification notification) {
    context.read<NotificationProvider>().deleteNotification(notification.id);
    NotificationService.showInfo(
      context,
      'Notification removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          context.read<NotificationProvider>().addNotification(notification);
        },
      ),
    );
  }
}

/// Individual notification item widget
class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = NotificationService.getColorForType(notification.type);
    final typeIcon = NotificationService.getIconForType(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SyntrakSpacing.lg),
        color: SyntrakColors.error,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Material(
        color: notification.isRead 
            ? SyntrakColors.surface 
            : SyntrakColors.primary.withOpacity(0.05),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: SyntrakColors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon or Avatar
                _buildLeadingWidget(typeColor, typeIcon),
                const SizedBox(width: SyntrakSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: SyntrakTypography.labelLarge.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: SyntrakColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.timeAgo,
                            style: SyntrakTypography.labelSmall.copyWith(
                              color: SyntrakColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: SyntrakColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(Color typeColor, IconData typeIcon) {
    if (notification.avatarUrl != null) {
      return Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(notification.avatarUrl!),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                typeIcon,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        typeIcon,
        color: typeColor,
        size: 22,
      ),
    );
  }
}
