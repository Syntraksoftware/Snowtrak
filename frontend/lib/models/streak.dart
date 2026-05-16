class Streak {
  final String userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? streakStartDate;
  final DateTime? streakEndDate;
  final DateTime updatedAt;

  Streak({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.streakStartDate,
    this.streakEndDate,
    required this.updatedAt,
  });

  bool get isOnStreak => streakStartDate != null && streakEndDate == null;

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      userId: json['user_id'],
      currentStreakDays: json['current_streak_days'] ?? 0,
      longestStreakDays: json['longest_streak_days'] ?? 0,
      streakStartDate: json['streak_start_date'] != null ? DateTime.parse(json['streak_start_date']) : null,
      streakEndDate: json['streak_end_date'] != null ? DateTime.parse(json['streak_end_date']) : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_streak_days': currentStreakDays,
      'longest_streak_days': longestStreakDays,
      'streak_start_date': streakStartDate?.toIso8601String(),
      'streak_end_date': streakEndDate?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
