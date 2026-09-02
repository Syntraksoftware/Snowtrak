/// What a duel or a board measures.
///
/// The wire values match `domain/competition/metrics.py`; a rename is a
/// two-sided break.
enum DuelMetric {
  vertical('vertical', 'Most Vertical', 'Highest total descent wins'),
  speed('speed', 'Top Speed', 'Single fastest recorded speed wins'),
  distance('distance', 'Total Distance', 'Greatest total ski distance wins');

  const DuelMetric(this.value, this.label, this.blurb);

  final String value;
  final String label;
  final String blurb;

  static DuelMetric fromValue(String? value) => DuelMetric.values.firstWhere(
        (metric) => metric.value == value,
        orElse: () => DuelMetric.vertical,
      );
}

/// How long a duel runs once accepted.
enum DuelDuration {
  today('today', 'Today only', 'Ends at midnight'),
  weekend('weekend', 'This weekend', 'Friday to Sunday'),
  week('week', 'This week', '7 days from acceptance');

  const DuelDuration(this.value, this.label, this.blurb);

  final String value;
  final String label;
  final String blurb;

  static DuelDuration fromValue(String? value) =>
      DuelDuration.values.firstWhere(
        (duration) => duration.value == value,
        orElse: () => DuelDuration.week,
      );
}

enum DuelStatus {
  pending,
  active,
  finished,
  declined,
  cancelled,
  expired;

  static DuelStatus fromValue(String? value) => DuelStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => DuelStatus.pending,
      );
}

/// One head-to-head.
///
/// Carries the rules that read off its own fields — whether the window has
/// closed, who won from this viewer's side, how long is left. The server
/// decides all of them again; these exist so a screen never has to.
class Duel {
  const Duel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.metric,
    required this.duration,
    required this.status,
    required this.createdAt,
    this.startsAt,
    this.endsAt,
    this.challengerValue,
    this.opponentValue,
    this.winnerId,
    this.settledAt,
    this.challengerName,
    this.challengerAvatarUrl,
    this.opponentName,
    this.opponentAvatarUrl,
  });

  factory Duel.fromJson(Map<String, dynamic> json) {
    return Duel(
      id: json['id'] as String? ?? '',
      challengerId: json['challenger_id'] as String? ?? '',
      opponentId: json['opponent_id'] as String? ?? '',
      metric: DuelMetric.fromValue(json['metric'] as String?),
      duration: DuelDuration.fromValue(json['duration'] as String?),
      status: DuelStatus.fromValue(json['status'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      challengerValue: (json['challenger_value'] as num?)?.toDouble(),
      opponentValue: (json['opponent_value'] as num?)?.toDouble(),
      winnerId: json['winner_id'] as String?,
      settledAt: DateTime.tryParse(json['settled_at'] as String? ?? ''),
      challengerName: json['challenger_name'] as String?,
      challengerAvatarUrl: json['challenger_avatar_url'] as String?,
      opponentName: json['opponent_name'] as String?,
      opponentAvatarUrl: json['opponent_avatar_url'] as String?,
    );
  }

  final String id;
  final String challengerId;
  final String opponentId;
  final DuelMetric metric;
  final DuelDuration duration;
  final DuelStatus status;
  final DateTime createdAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final double? challengerValue;
  final double? opponentValue;
  final String? winnerId;
  final DateTime? settledAt;

  /// Filled by the list and detail endpoints from one profiles read per
  /// page. Null on a payload that predates them.
  final String? challengerName;
  final String? challengerAvatarUrl;
  final String? opponentName;
  final String? opponentAvatarUrl;

  bool get isLive =>
      status == DuelStatus.pending || status == DuelStatus.active;

  /// A finished duel where neither player came out ahead.
  bool get isDraw => status == DuelStatus.finished && winnerId == null;

  String otherPlayer(String viewerId) =>
      viewerId == challengerId ? opponentId : challengerId;

  String otherPlayerName(String viewerId) {
    final name =
        viewerId == challengerId ? opponentName : challengerName;
    return (name == null || name.isEmpty) ? 'Skier' : name;
  }

  String? otherPlayerAvatarUrl(String viewerId) =>
      viewerId == challengerId ? opponentAvatarUrl : challengerAvatarUrl;

  double? valueFor(String userId) =>
      userId == challengerId ? challengerValue : opponentValue;

  /// Whether [viewerId] is the one being asked, and the ask still stands.
  bool awaitingAnswerFrom(String viewerId) =>
      status == DuelStatus.pending && viewerId == opponentId;

  /// Whether [viewerId] sent this and is waiting.
  bool awaitingAnswerFor(String viewerId) =>
      status == DuelStatus.pending && viewerId == challengerId;

  /// Time left in the window, or `null` when there is no window running.
  ///
  /// Clamped at zero: a duel whose window closed a minute ago is over, not
  /// running backwards, and the screen shows a result rather than a
  /// negative countdown.
  Duration? remainingAt(DateTime now) {
    final end = endsAt;
    if (status != DuelStatus.active || end == null) return null;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Time left to answer, on the same terms as `remainingAt`.
  Duration? answerWindowAt(DateTime now) {
    if (status != DuelStatus.pending) return null;
    final left = createdAt.add(inviteTtl).difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// Mirrors `INVITE_TTL` in the backend's duel domain. A challenge shown as
/// answerable that the server has already expired is a worse lie than a
/// duplicated constant.
const Duration inviteTtl = Duration(hours: 48);

/// A player's head-to-head history.
class DuelRecord {
  const DuelRecord({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.recent = const <String>[],
  });

  factory DuelRecord.fromJson(Map<String, dynamic> json) {
    final recent = json['recent'];
    return DuelRecord(
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      recent: recent is List ? recent.map((e) => e.toString()).toList() : const [],
    );
  }

  final int wins;
  final int losses;
  final int draws;

  /// Most recent first, each `W`, `L` or `D`.
  final List<String> recent;

  int get played => wins + losses + draws;

  /// Null rather than zero when nothing has been played — "0%" and "no
  /// duels yet" are different things to show.
  double? get winRate => played == 0 ? null : wins / played;
}
