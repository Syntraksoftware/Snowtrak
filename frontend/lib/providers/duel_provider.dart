import 'package:flutter/foundation.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/services/duel_service.dart';

/// Duel state for the leaderboard tab and the duel screens.
///
/// Holds one page of the viewer's duels and splits it into the three things
/// a screen actually asks for: what needs an answer, what is running, what
/// is over. The split is here rather than in each screen because "needs an
/// answer" depends on who is looking, and a widget that recomputes that is a
/// widget that will get it wrong once.
class DuelProvider extends ChangeNotifier {
  DuelProvider({required DuelService duelService})
      : _duelService = duelService;

  final DuelService _duelService;

  List<Duel> _duels = const [];
  bool _isLoading = false;
  String? _error;
  String _viewerId = '';

  List<Duel> get duels => _duels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Challenges waiting on the viewer to accept or decline.
  List<Duel> get incoming =>
      _duels.where((duel) => duel.awaitingAnswerFrom(_viewerId)).toList();

  /// Challenges the viewer sent that nobody has answered.
  List<Duel> get outgoing =>
      _duels.where((duel) => duel.awaitingAnswerFor(_viewerId)).toList();

  List<Duel> get active =>
      _duels.where((duel) => duel.status == DuelStatus.active).toList();

  bool get hasIncoming => incoming.isNotEmpty;

  /// Loads the viewer's duels.
  ///
  /// ponytail: one page of 20, no pagination. A duel list is a screen, and
  /// nobody has 20 live duels; add paging when the finished ones need
  /// scrolling back through.
  Future<void> load(String viewerId) async {
    _viewerId = viewerId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _duelService.list(limit: 20);
    switch (result) {
      case AppSuccess(:final value):
        _duels = value;
        _error = null;
      case AppFailure(:final error):
        _error = error.userMessage;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<AppResult<Duel>> challenge({
    required String opponentId,
    required DuelMetric metric,
    required DuelDuration duration,
  }) async {
    final result = await _duelService.challenge(
      opponentId: opponentId,
      metric: metric,
      duration: duration,
    );
    if (result case AppSuccess(:final value)) {
      _replaceOrInsert(value);
    }
    return result;
  }

  Future<AppResult<Duel>> accept(String duelId) => _answer(
        () => _duelService.accept(duelId),
      );

  Future<AppResult<Duel>> decline(String duelId) => _answer(
        () => _duelService.decline(duelId),
      );

  Future<AppResult<Duel>> cancel(String duelId) => _answer(
        () => _duelService.cancel(duelId),
      );

  /// Re-reads one duel.
  ///
  /// The server settles a closed window on read, so opening a finished duel
  /// is also what produces its result.
  Future<AppResult<Duel>> refreshOne(String duelId) => _answer(
        () => _duelService.get(duelId),
      );

  Future<AppResult<Duel>> _answer(Future<AppResult<Duel>> Function() call) async {
    final result = await call();
    if (result case AppSuccess(:final value)) {
      _replaceOrInsert(value);
    }
    return result;
  }

  void _replaceOrInsert(Duel duel) {
    final index = _duels.indexWhere((existing) => existing.id == duel.id);
    final next = List<Duel>.of(_duels);
    if (index == -1) {
      next.insert(0, duel);
    } else {
      next[index] = duel;
    }
    _duels = next;
    notifyListeners();
  }
}
