import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/screens/leaderboard/duel_formatting.dart';

Duel _duel({
  DuelStatus status = DuelStatus.pending,
  DateTime? createdAt,
  DateTime? endsAt,
  String? winnerId,
}) {
  return Duel(
    id: 'duel-1',
    challengerId: 'alex',
    opponentId: 'jordan',
    metric: DuelMetric.vertical,
    duration: DuelDuration.week,
    status: status,
    createdAt: createdAt ?? DateTime.utc(2026, 9, 2, 12),
    endsAt: endsAt,
    winnerId: winnerId,
  );
}

void main() {
  final now = DateTime.utc(2026, 9, 2, 12);

  group('who is being asked', () {
    test('only the challenged player is waiting to answer', () {
      final duel = _duel();
      expect(duel.awaitingAnswerFrom('jordan'), isTrue);
      expect(duel.awaitingAnswerFrom('alex'), isFalse);
      expect(duel.awaitingAnswerFor('alex'), isTrue);
    });

    test('an accepted duel is nobody to answer for', () {
      final duel = _duel(status: DuelStatus.active);
      expect(duel.awaitingAnswerFrom('jordan'), isFalse);
      expect(duel.awaitingAnswerFor('alex'), isFalse);
    });
  });

  group('countdowns', () {
    test('a closed window reads as zero, never as time running backwards', () {
      final duel = _duel(
        status: DuelStatus.active,
        endsAt: now.subtract(const Duration(hours: 3)),
      );
      expect(duel.remainingAt(now), Duration.zero);
      expect(formatRemaining(duel.remainingAt(now)!), 'Ended');
    });

    test('a pending challenge counts down from the 48 hour invite window', () {
      final duel = _duel(createdAt: now.subtract(const Duration(hours: 47)));
      expect(duel.answerWindowAt(now), const Duration(hours: 1));
    });

    test('a duel with no window has no countdown', () {
      expect(_duel().remainingAt(now), isNull);
      expect(_duel(status: DuelStatus.finished).answerWindowAt(now), isNull);
    });
  });

  group('results', () {
    test('a finished duel with no winner is a draw, not a loss', () {
      expect(_duel(status: DuelStatus.finished).isDraw, isTrue);
      expect(
        _duel(status: DuelStatus.finished, winnerId: 'alex').isDraw,
        isFalse,
      );
      // Pending with no winner is not a draw -- it has not been played.
      expect(_duel().isDraw, isFalse);
    });

    test('a record with nothing played has no win rate rather than zero', () {
      expect(const DuelRecord().winRate, isNull);
      expect(const DuelRecord(wins: 1, losses: 1).winRate, 0.5);
    });
  });

  group('decoding', () {
    test('an unknown metric falls back rather than throwing', () {
      // A newer server can add one; a crash on the list screen is worse
      // than showing the default.
      final duel = Duel.fromJson({
        'id': 'd',
        'challenger_id': 'alex',
        'opponent_id': 'jordan',
        'metric': 'most_runs',
        'duration': 'week',
        'status': 'active',
        'created_at': '2026-09-02T12:00:00Z',
      });
      expect(duel.metric, DuelMetric.vertical);
      expect(duel.status, DuelStatus.active);
    });
  });

  group('formatting', () {
    test('vertical is shown in feet, thousands separated', () {
      expect(formatMetricValue(DuelMetric.vertical, 1000), '3,281 ft');
    });

    test('speed converts km/h to mph', () {
      expect(formatMetricValue(DuelMetric.speed, 100), '62.1 mph');
    });
  });
}
