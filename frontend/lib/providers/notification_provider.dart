import 'package:flutter/foundation.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/models/notification.dart';
import 'package:snowtrak/services/duel_service.dart';
import 'package:snowtrak/services/follow_service.dart';

/// Notification state.
///
/// Every notification here is *derived*, not stored: from a pending follow
/// request, and from a duel challenge waiting on the viewer's answer. Those
/// are the two notification-shaped events the backend actually has.
/// `/api/v1/notifications/*` was a single global in-memory queue with no user
/// id and no auth, so reading it would have shown every user each other's
/// notifications -- this provider does not touch it.
///
/// ponytail: derive instead of persist. At a third source, or the first one
/// that is not a list the user can already see somewhere else, give
/// notifications their own table and read that.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    required FollowService followService,
    required DuelService duelService,
  })  : _followService = followService,
        _duelService = duelService;

  final FollowService _followService;
  final DuelService _duelService;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

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

  /// Rebuilds the list from pending follow requests and pending duels.
  ///
  /// [viewerId] decides which duels count: a pending duel the viewer *sent*
  /// is not a notification, it is something they are waiting on. Without it
  /// only follow requests are read, which is the case at app start before
  /// auth has resolved.
  ///
  /// ponytail: one page of each, so it stops at 20 apiece -- the same
  /// ceiling the profile header's badge already accepts.
  Future<void> loadNotifications({String? viewerId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final requests = await _followService.getRequests(limit: 20);
    final duels = (viewerId == null || viewerId.isEmpty)
        ? null
        : await _duelService.list(status: DuelStatus.pending, limit: 20);

    final combined = <AppNotification>[];
    switch (requests) {
      case AppSuccess(:final value):
        combined.addAll(value.map(_followRequestNotification));
        _error = null;
      case AppFailure(:final error):
        _error = error.userMessage;
    }
    if (duels case AppSuccess(:final value)) {
      combined.addAll(
        value
            .where((duel) => duel.awaitingAnswerFrom(viewerId!))
            .map(_duelNotification),
      );
    }
    // Newest first across both sources; each source is already ordered, but
    // interleaving them is the whole point of merging.
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _notifications = combined;
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

  /// One pending duel, as a notification.
  ///
  /// `metadata['duel_id']` is what the tap handler opens. The duel screen
  /// handles every state, so a challenge that was answered from another
  /// device still opens to something truthful rather than to a dead accept
  /// button.
  static AppNotification _duelNotification(Duel duel) {
    final name = duel.challengerName ?? 'Someone';
    return AppNotification(
      id: 'duel:${duel.id}',
      type: NotificationType.challenge,
      title: 'Battle challenge',
      message: '$name challenged you to ${duel.metric.label}',
      createdAt: duel.createdAt,
      senderName: name,
      metadata: {'duel_id': duel.id},
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
