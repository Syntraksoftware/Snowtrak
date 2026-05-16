/// Notification model for Syntrak app
/// Represents different types of in-app notifications

enum NotificationType {
  kudos,
  comment,
  follow,
  friendActivity,
  challenge,
  group,
  weather,
  powderDay, // Fresh snow notification
  achievement, // New achievement unlocked
  system, // System notification
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute; // Optional: Route to navigate when tapped
  final Map<String, dynamic>? metadata; // Optional: Additional data
  final String? avatarUrl; // Optional: User avatar for social notifications
  final String? senderName; // Optional: Name of the person who triggered this

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.metadata,
    this.avatarUrl,
    this.senderName,
  });

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? metadata,
    String? avatarUrl,
    String? senderName,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      senderName: senderName ?? this.senderName,
    );
  }

  /// Convert from JSON (for API responses)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      actionRoute: json['action_route'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      avatarUrl: json['avatar_url'] as String?,
      senderName: json['sender_name'] as String?,
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'action_route': actionRoute,
      'metadata': metadata,
      'avatar_url': avatarUrl,
      'sender_name': senderName,
    };
  }

  ///  Relative time string (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
