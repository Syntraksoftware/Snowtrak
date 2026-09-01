import 'package:flutter/foundation.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/notification.dart';
import 'package:snowtrak/services/follow_service.dart';

/// Notification state.
///
/// Every notification here is *derived* from a pending follow request, not
/// stored: `/api/v1/follows/me/requests` is the only real notification-shaped
/// event the backend has today. `/api/v1/notifications/*` is a single global
/// in-memory queue with no user id and no auth, so reading it would have shown
/// every user each other's notifications -- this provider no longer touches it.
///
/// ponytail: derive instead of persist. When a second real event exists
/// (kudos, comments), give notifications their own table and read that.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required FollowService followService})
      : _followService = followService;

  final FollowService _followService;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Callback for showing banner notifications (set by the app)
  void Function(AppNotification)? onNewNotification;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Check if there are any unread notifications
  bool get hasUnread => unreadCount > 0;

  /// Get notifications grouped by date
  Map<String, List<AppNotification>> get groupedNotifications {
    final Map<String, List<AppNotification>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in _notifications) {
      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      String key;
      if (notificationDate == today) {
        key = 'Today';
      } else if (notificationDate == yesterday) {
        key = 'Yesterday';
      } else if (now.difference(notification.createdAt).inDays < 7) {
        key = 'This Week';
      } else {
        key = 'Earlier';
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(notification);
    }

    return grouped;
  }

  /// Rebuild the list from the pending follow requests.
  ///
  /// ponytail: one page, so it stops at 20 -- the same ceiling the profile
  /// header's badge already accepts.
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _followService.getRequests(limit: 20);

    switch (result) {
      case AppSuccess(:final value):
        _notifications = value.map(_followRequestNotification).toList();
        _error = null;
      case AppFailure(:final error):
        _error = error.userMessage;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new notification
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Mark a single notification as read.
  ///
  /// Local only: the list is derived, so this does not survive a reload. The
  /// request itself is cleared by approving or denying it.
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Delete a notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// One pending follow request, as a notification.
  ///
  /// `metadata['user_id']` is what the tap handler pushes a profile for, and
  /// it doubles as the id: one request per requester, so it is already unique
  /// and survives the list being rebuilt.
  static AppNotification _followRequestNotification(Map<String, dynamic> row) {
    final userId = (row['user_id'] as String?)?.trim() ?? '';
    final name = _displayName(row);
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
    return AppNotification(
      id: 'follow_request:$userId',
      type: NotificationType.follow,
      title: 'Follow request',
      message: '$name asked to follow you',
      createdAt: createdAt ?? DateTime.now(),
      senderName: name,
      metadata: {'user_id': userId},
    );
  }

  static String _displayName(Map<String, dynamic> row) {
    final first = (row['first_name'] as String?)?.trim() ?? '';
    final last = (row['last_name'] as String?)?.trim() ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    final email = (row['email'] as String?)?.trim() ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Someone';
  }
}
