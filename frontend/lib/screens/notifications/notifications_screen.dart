import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/notification.dart';
import 'package:snowtrak/providers/notification_provider.dart';
import 'package:snowtrak/services/notification_service.dart';

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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
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
                      color: context.colors.primary,
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
      padding: const EdgeInsets.symmetric(vertical: SnowtrakSpacing.md),
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
                horizontal: SnowtrakSpacing.md,
                vertical: SnowtrakSpacing.sm,
              ),
              child: Text(
                section,
                style: SnowtrakTypography.labelMedium.copyWith(
                  color: context.colors.textTertiary,
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
            const SizedBox(height: SnowtrakSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SnowtrakSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: context.colors.textTertiary,
              ),
            ),
            const SizedBox(height: SnowtrakSpacing.lg),
            Text(
              'No Notifications',
              style: SnowtrakTypography.headlineSmall.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: SnowtrakSpacing.sm),
            Text(
              'When you get notifications, they\'ll show up here',
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
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
        padding: const EdgeInsets.all(SnowtrakSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.colors.error,
            ),
            const SizedBox(height: SnowtrakSpacing.md),
            Text(
              provider.error ?? 'Something went wrong',
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SnowtrakSpacing.lg),
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
    final typeColor = NotificationService.getColorForType(context, notification.type);
    final typeIcon = NotificationService.getIconForType(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SnowtrakSpacing.lg),
        color: context.colors.error,
        child: Icon(
          Icons.delete_outline,
          color: context.colors.textOnPrimary,
        ),
      ),
      child: Material(
        color: notification.isRead 
            ? context.colors.surface 
            : context.colors.primary.withOpacity(0.05),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(SnowtrakSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon or Avatar
                _buildLeadingWidget(context, typeColor, typeIcon),
                const SizedBox(width: SnowtrakSpacing.md),
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
                              style: SnowtrakTypography.labelLarge.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.timeAgo,
                            style: SnowtrakTypography.labelSmall.copyWith(
                              color: context.colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: SnowtrakTypography.bodyMedium.copyWith(
                          color: context.colors.textSecondary,
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
                      color: context.colors.primary,
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

  Widget _buildLeadingWidget(
      BuildContext context, Color typeColor, IconData typeIcon) {
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
                border: Border.all(color: context.colors.surface, width: 2),
              ),
              child: Icon(
                typeIcon,
                size: 10,
                color: context.colors.textOnPrimary,
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
