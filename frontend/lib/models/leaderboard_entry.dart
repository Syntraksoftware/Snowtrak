import 'package:snowtrak/models/duel.dart';

/// One row of a board.
///
/// Deliberately has no activity id. The board shows a name, a total and a
/// rank; linking to an activity is what would leak a private one.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.value,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.countryCode,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      displayName: json['display_name'] as String? ?? 'Skier',
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }

  final int rank;
  final String userId;
  final double value;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? countryCode;
}

/// A board page and the terms it was read under.
class Leaderboard {
  const Leaderboard({
    required this.metric,
    required this.scope,
    required this.weekStart,
    required this.settled,
    required this.entries,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'];
    return Leaderboard(
      metric: DuelMetric.fromValue(json['metric'] as String?),
      scope: json['scope'] as String? ?? globalScope,
      weekStart: json['week_start'] as String? ?? '',
      settled: json['settled'] as bool? ?? false,
      entries: entries is List
          ? entries
              .whereType<Map<String, dynamic>>()
              .map(LeaderboardEntry.fromJson)
              .toList()
          : const <LeaderboardEntry>[],
    );
  }

  final DuelMetric metric;

  /// `globalScope` or an ISO 3166-1 alpha-2 country code.
  final String scope;
  final String weekStart;

  /// False for the week being skied, true for a settled snapshot.
  final bool settled;
  final List<LeaderboardEntry> entries;
}

/// Where the viewer stands, however deep in the board.
class LeaderboardPlacing {
  const LeaderboardPlacing({this.rank, this.value = 0});

  factory LeaderboardPlacing.fromJson(Map<String, dynamic> json) {
    return LeaderboardPlacing(
      rank: (json['rank'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Null when the viewer has not placed this week.
  final int? rank;
  final double value;
}

const String globalScope = 'global';
