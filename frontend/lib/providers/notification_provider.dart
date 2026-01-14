import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:syntrak/models/notification.dart';

/// Provider for managing notification state
/// Handles the list of notifications, unread count, and notification operations
/// Includes polling for backend-triggered test notifications
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  final Dio _dio = Dio();

  // Backend URL for notification polling
  static const String _baseUrl = 'http://127.0.0.1:8080/api/v1';

  // Callback for showing banner notifications (set by the app)
  Function(AppNotification)? onNewNotification;

  NotificationProvider() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  // Getters
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

  /// Start polling for backend notifications
  /// Call this when the app starts or user logs in
  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    stopPolling(); // Stop any existing timer
    print('🔔 Starting notification polling (every ${interval.inSeconds}s)');
    _pollingTimer =
        Timer.periodic(interval, (_) => _fetchPendingNotifications());
  }

  /// Stop polling for notifications
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch pending notifications from backend
  Future<void> _fetchPendingNotifications() async {
    try {
      final response = await _dio.get('/notifications/pending');

      if (response.data is List && (response.data as List).isNotEmpty) {
        final List<dynamic> data = response.data;

        for (final json in data) {
          final notification = AppNotification(
            id: json['id'],
            type: _parseNotificationType(json['type']),
            title: json['title'],
            message: json['message'],
            createdAt: DateTime.parse(json['created_at']),
            isRead: json['is_read'] ?? false,
            senderName: json['sender_name'],
            avatarUrl: json['avatar_url'],
            actionRoute: json['action_route'],
          );

          // Add to list
          _notifications.insert(0, notification);

          // Trigger callback for showing banner/toast
          if (onNewNotification != null) {
            onNewNotification!(notification);
          }

          print('🔔 Received notification: ${notification.title}');
        }

        notifyListeners();
      }
    } catch (e) {
      // Silently fail - backend might not be running
      // Only log in debug mode
      if (kDebugMode) {
        print('📡 Notification polling: ${e.toString().split('\n').first}');
      }
    }
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'kudos':
        return NotificationType.kudos;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'friendActivity':
        return NotificationType.friendActivity;
      case 'challenge':
        return NotificationType.challenge;
      case 'group':
        return NotificationType.group;
      case 'weather':
        return NotificationType.weather;
      case 'powderDay':
        return NotificationType.powderDay;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.system;
    }
  }

  /// Load notifications (from API or mock data)
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from backend history first
      try {
        final response = await _dio.get('/notifications/history');
        if (response.data is List && (response.data as List).isNotEmpty) {
          _notifications = (response.data as List)
              .map((json) => AppNotification(
                    id: json['id'],
                    type: _parseNotificationType(json['type']),
                    title: json['title'],
                    message: json['message'],
                    createdAt: DateTime.parse(json['created_at']),
                    isRead: json['is_read'] ?? false,
                    senderName: json['sender_name'],
                    avatarUrl: json['avatar_url'],
                    actionRoute: json['action_route'],
                  ))
              .toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        // Backend not available, use mock data
      }

      // Fallback to mock data
      _notifications = _generateMockNotifications();
      _isLoading = false;
      notifyListeners();

      // Start polling for test notifications
      startPolling();
    } catch (e) {
      _error = 'Failed to load notifications';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Mark a single notification as read
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

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  /// Generate mock notifications for demonstration
  List<AppNotification> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        type: NotificationType.kudos,
        title: 'New Kudos!',
        message: 'Sarah gave kudos to your morning ski run',
        createdAt: now.subtract(const Duration(minutes: 5)),
        senderName: 'Sarah Chen',
        isRead: false,
      ),
      AppNotification(
        id: '2',
        type: NotificationType.comment,
        title: 'New Comment',
        message: 'Mike commented: "Amazing run! What trail was that?"',
        createdAt: now.subtract(const Duration(hours: 1)),
        senderName: 'Mike Johnson',
        isRead: false,
      ),
      AppNotification(
        id: '3',
        type: NotificationType.follow,
        title: 'New Follower',
        message: 'Alex started following you',
        createdAt: now.subtract(const Duration(hours: 3)),
        senderName: 'Alex Kim',
        isRead: false,
      ),
      AppNotification(
        id: '4',
        type: NotificationType.powderDay,
        title: '❄️ Powder Day Alert!',
        message: '12 inches of fresh snow at Whistler Blackcomb',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      AppNotification(
        id: '5',
        type: NotificationType.challenge,
        title: 'Challenge Progress',
        message: 'You\'re 75% done with the January Challenge!',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '6',
        type: NotificationType.achievement,
        title: '🏆 New Achievement!',
        message: 'You unlocked "Early Bird" - 10 runs before 9 AM',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
      ),
      AppNotification(
        id: '7',
        type: NotificationType.friendActivity,
        title: 'Friend Activity',
        message: 'Emma completed a 15km cross-country ski',
        createdAt: now.subtract(const Duration(days: 2)),
        senderName: 'Emma Wilson',
        isRead: true,
      ),
      AppNotification(
        id: '8',
        type: NotificationType.group,
        title: 'Group Update',
        message: 'Weekend Warriors posted a new event: "Sunday Ski Trip"',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AppNotification(
        id: '9',
        type: NotificationType.weather,
        title: 'Weather Alert',
        message: 'High winds expected at the summit tomorrow',
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }
}
