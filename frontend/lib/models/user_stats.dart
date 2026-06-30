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
