class UserStats {
  const UserStats({
    required this.weekStart,
    required this.weeklyDistanceKm,
    required this.weeklyTimeMin,
    required this.weeklyElevGain,
    required this.weeklySessionCount,
    required this.lastWeekSessionCount,
    required this.yearlyDistanceKm,
    required this.yearlyTimeMin,
    required this.yearlyElevGain,
    required this.yearlySessionCount,
    required this.allTimeDistanceKm,
    required this.allTimeTimeMin,
    required this.allTimeElevGain,
    required this.allTimeSessionCount,
    required this.activityDays,
    required this.bestEfforts,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      weekStart: DateTime.parse(json['week_start'] as String),
      weeklyDistanceKm: (json['weekly_distance_km'] as num).toDouble(),
      weeklyTimeMin: json['weekly_time_min'] as int,
      weeklyElevGain: (json['weekly_elev_gain_m'] as num).toDouble(),
      weeklySessionCount: json['weekly_session_count'] as int,
      lastWeekSessionCount: json['last_week_session_count'] as int,
      yearlyDistanceKm: (json['yearly_distance_km'] as num).toDouble(),
      yearlyTimeMin: json['yearly_time_min'] as int,
      yearlyElevGain: (json['yearly_elev_gain_m'] as num).toDouble(),
      yearlySessionCount: json['yearly_session_count'] as int,
      allTimeDistanceKm: (json['all_time_distance_km'] as num).toDouble(),
      allTimeTimeMin: json['all_time_time_min'] as int,
      allTimeElevGain: (json['all_time_elev_gain_m'] as num).toDouble(),
      allTimeSessionCount: json['all_time_session_count'] as int,
      activityDays: (json['activity_days'] as List<dynamic>)
          .map((d) => DateTime.parse(d as String))
          .toSet(),
      bestEfforts: (json['best_efforts'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      currentStreak: json['current_streak_weeks'] as int,
      longestStreak: json['longest_streak_weeks'] as int,
    );
  }

  final DateTime weekStart;
  final double weeklyDistanceKm;
  final int weeklyTimeMin;
  final double weeklyElevGain;
  final int weeklySessionCount;
  final int lastWeekSessionCount;
  final double yearlyDistanceKm;
  final int yearlyTimeMin;
  final double yearlyElevGain;
  final int yearlySessionCount;
  final double allTimeDistanceKm;
  final int allTimeTimeMin;
  final double allTimeElevGain;
  final int allTimeSessionCount;
  final Set<DateTime> activityDays;
  final List<Map<String, dynamic>> bestEfforts;
  final int currentStreak;
  final int longestStreak;
}
