import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/notification_provider.dart';
import 'package:syntrak/screens/notifications/notifications_screen.dart';

/// A reusable notification bell icon with unread badge
/// 
/// Usage:
/// ```dart
/// // In an AppBar
/// AppBar(
///   actions: [
///     NotificationBellIcon(),
///   ],
/// )
/// ```
class NotificationBellIcon extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBellIcon({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: iconSize,
                color: iconColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              tooltip: 'Notifications',
            ),
            // Badge for unread count
            if (provider.hasUnread)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: SyntrakColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SyntrakColors.surface,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      provider.unreadCount > 9 
                          ? '9+' 
                          : provider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
