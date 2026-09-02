import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/models/leaderboard_entry.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/providers/duel_provider.dart';
import 'package:snowtrak/screens/leaderboard/duel_detail_screen.dart';
import 'package:snowtrak/screens/leaderboard/duel_formatting.dart';
import 'package:snowtrak/screens/leaderboard/duel_terms_screen.dart';
import 'package:snowtrak/screens/profile/user_profile_screen.dart';
import 'package:snowtrak/services/leaderboard_service.dart';
import 'package:snowtrak/ui/st/st.dart';

const String friendsScope = 'friends';

/// The Community tab's leaderboard.
///
/// Two boards, and the difference matters: Global ranks everyone who opted
/// an activity in, Friends ranks the people you mutually follow. Only the
/// second carries a Challenge button, because a duel needs a mutual follow
/// to be offered at all.
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  final LeaderboardService _leaderboardService = sl<LeaderboardService>();

  String _scope = friendsScope;
  DuelMetric _metric = DuelMetric.vertical;

  Leaderboard? _board;
  LeaderboardPlacing? _placing;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final board = await _leaderboardService.getBoard(
      metric: _metric,
      scope: _scope,
    );
    final placing = await _leaderboardService.getMyPlacing(
      metric: _metric,
      scope: _scope,
    );
    if (!mounted) return;

    final viewerId = context.read<AuthProvider>().user?.id ?? '';
    if (viewerId.isNotEmpty) {
      await context.read<DuelProvider>().load(viewerId);
    }
    if (!mounted) return;

    setState(() {
      switch (board) {
        case AppSuccess(:final value):
          _board = value;
          _error = null;
        case AppFailure(:final error):
          // No board rather than a stale one: standings that are wrong are
          // worse than standings that are missing.
          _board = null;
          _error = error.userMessage;
      }
      _placing = placing is AppSuccess<LeaderboardPlacing> ? placing.value : null;
      _isLoading = false;
    });
  }

  void _select({String? scope, DuelMetric? metric}) {
    setState(() {
      _scope = scope ?? _scope;
      _metric = metric ?? _metric;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final viewerId = context.watch<AuthProvider>().user?.id ?? '';
    final incoming = context.watch<DuelProvider>().incoming;

    return RefreshIndicator(
      onRefresh: _load,
      color: context.colors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SnowtrakSpacing.md,
          SnowtrakSpacing.md,
          SnowtrakSpacing.md,
          SnowtrakSpacing.xxl,
        ),
        children: [
          _ScopeToggle(
            scope: _scope,
            onChanged: (scope) => _select(scope: scope),
          ),
          const SizedBox(height: SnowtrakSpacing.smd),
          _MetricChips(
            metric: _metric,
            onChanged: (metric) => _select(metric: metric),
          ),
          if (incoming.isNotEmpty) ...[
            const SizedBox(height: SnowtrakSpacing.md),
            _IncomingBanner(duels: incoming, viewerId: viewerId),
          ],
          const SizedBox(height: SnowtrakSpacing.md),
          _PlacingCard(metric: _metric, placing: _placing),
          const SizedBox(height: SnowtrakSpacing.md),
          ..._boardBody(viewerId),
        ],
      ),
    );
  }

  List<Widget> _boardBody(String viewerId) {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: SnowtrakSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final error = _error;
    if (error != null) {
      return [_BoardMessage(message: error, onRetry: _load)];
    }
    final entries = _board?.entries ?? const <LeaderboardEntry>[];
    if (entries.isEmpty) {
      return [
        _BoardMessage(
          message: _scope == friendsScope
              ? 'Nobody you follow has put an activity on the board this week.'
              : 'No activities on the board this week yet.',
          onRetry: _load,
        ),
      ];
    }
    return entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: SnowtrakSpacing.sm),
            child: _BoardRow(
              entry: entry,
              metric: _metric,
              // Only the friends board can offer a duel.
              challengeable: _scope == friendsScope && entry.userId != viewerId,
            ),
          ),
        )
        .toList();
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});

  final String scope;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SnowtrakSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
      ),
      child: Row(
        children: [
          _ToggleHalf(
            label: 'Friends',
            selected: scope == friendsScope,
            onTap: () => onChanged(friendsScope),
          ),
          _ToggleHalf(
            label: 'Global',
            selected: scope == globalScope,
            onTap: () => onChanged(globalScope),
          ),
        ],
      ),
    );
  }
}

class _ToggleHalf extends StatelessWidget {
  const _ToggleHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? context.colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
          ),
          child: Text(
            label,
            style: SnowtrakTypography.labelLarge.copyWith(
              color: selected
                  ? context.colors.textPrimary
                  : context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChips extends StatelessWidget {
  const _MetricChips({required this.metric, required this.onChanged});

  final DuelMetric metric;
  final ValueChanged<DuelMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DuelMetric.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: SnowtrakSpacing.sm),
        itemBuilder: (context, index) {
          final option = DuelMetric.values[index];
          final selected = option == metric;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onChanged(option),
            label: Text(option.label),
            labelStyle: SnowtrakTypography.labelMedium.copyWith(
              color: selected
                  ? context.colors.textOnPrimary
                  : context.colors.textSecondary,
            ),
            selectedColor: context.colors.primary,
            backgroundColor: context.colors.surfaceVariant,
            showCheckmark: false,
            side: BorderSide(color: context.colors.border),
          );
        },
      ),
    );
  }
}

class _IncomingBanner extends StatelessWidget {
  const _IncomingBanner({required this.duels, required this.viewerId});

  final List<Duel> duels;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    final first = duels.first;
    final more = duels.length - 1;
    return StCard(
      color: context.colors.primary,
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      onTap: () => openDuel(context, first.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  more > 0
                      ? '${duels.length} battle challenges'
                      : 'New battle challenge',
                  style: SnowtrakTypography.labelLarge.copyWith(
                    color: context.colors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xxs),
                Text(
                  '${first.otherPlayerName(viewerId)} · '
                  '${first.metric.label}',
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: context.colors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textOnPrimary),
        ],
      ),
    );
  }
}

class _PlacingCard extends StatelessWidget {
  const _PlacingCard({required this.metric, required this.placing});

  final DuelMetric metric;
  final LeaderboardPlacing? placing;

  @override
  Widget build(BuildContext context) {
    final rank = placing?.rank;
    return StCard(
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your position',
                  style: SnowtrakTypography.labelMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xxs),
                Text(
                  rank == null
                      ? 'Not on the board yet'
                      : formatMetricValue(metric, placing?.value ?? 0),
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rank == null ? '—' : '#$rank',
            style: SnowtrakTypography.metricMedium.copyWith(
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.entry,
    required this.metric,
    required this.challengeable,
  });

  final LeaderboardEntry entry;
  final DuelMetric metric;
  final bool challengeable;

  @override
  Widget build(BuildContext context) {
    return StCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SnowtrakSpacing.md,
        vertical: SnowtrakSpacing.smd,
      ),
      onTap: () => openUserProfile(
        context,
        entry.userId,
        displayName: entry.displayName,
        username: entry.username,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: SnowtrakTypography.labelLarge.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SnowtrakTypography.labelLarge.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  formatMetricValue(metric, entry.value),
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (challengeable)
            TextButton(
              onPressed: () => openDuelTerms(
                context,
                opponentId: entry.userId,
                opponentName: entry.displayName,
              ),
              child: const Text('Challenge'),
            ),
        ],
      ),
    );
  }
}

class _BoardMessage extends StatelessWidget {
  const _BoardMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SnowtrakSpacing.xl),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.smd),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
