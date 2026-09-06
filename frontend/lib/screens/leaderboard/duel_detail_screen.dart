import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/providers/duel_provider.dart';
import 'package:snowtrak/screens/leaderboard/duel_formatting.dart';
import 'package:snowtrak/screens/profile/user_profile_screen.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Opens one duel. Works for every state, including a challenge waiting on
/// the viewer, so a notification tap has one destination rather than three.
Future<void> openDuel(BuildContext context, String duelId) async {
  if (duelId.trim().isEmpty) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => DuelDetailScreen(duelId: duelId)),
  );
}

class DuelDetailScreen extends StatefulWidget {
  const DuelDetailScreen({super.key, required this.duelId});

  final String duelId;

  @override
  State<DuelDetailScreen> createState() => _DuelDetailScreenState();
}

class _DuelDetailScreenState extends State<DuelDetailScreen> {
  Duel? _duel;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Reading a duel is also what settles it: the server scores a window that
  /// has closed before it answers, so opening a finished duel produces the
  /// result rather than waiting on the background sweep.
  Future<void> _load() async {
    final result = await context.read<DuelProvider>().refreshOne(widget.duelId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case AppSuccess(:final value):
          _duel = value;
          _error = null;
        case AppFailure(:final error):
          _error = error.userMessage;
      }
      _busy = false;
    });
  }

  Future<void> _answer(Future<AppResult<Duel>> Function() call) async {
    setState(() => _busy = true);
    final result = await call();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result case AppSuccess(:final value)) _duel = value;
    });
    if (result case AppFailure(:final error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewerId = context.watch<AuthProvider>().user?.id ?? '';
    final duel = _duel;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Battle'),
      ),
      body: SafeArea(
        child: duel == null
            ? Center(
                child: _busy
                    ? const CircularProgressIndicator()
                    : Text(
                        _error ?? 'Battle not found',
                        style: SnowtrakTypography.bodyMedium.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
              )
            : _body(duel, viewerId),
      ),
    );
  }

  Widget _body(Duel duel, String viewerId) {
    return ListView(
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      children: [
        _Versus(duel: duel, viewerId: viewerId),
        const SizedBox(height: SnowtrakSpacing.md),
        _Terms(duel: duel),
        const SizedBox(height: SnowtrakSpacing.md),
        _Status(duel: duel, viewerId: viewerId),
        const SizedBox(height: SnowtrakSpacing.lg),
        ..._actions(duel, viewerId),
      ],
    );
  }

  List<Widget> _actions(Duel duel, String viewerId) {
    if (duel.awaitingAnswerFrom(viewerId)) {
      final provider = context.read<DuelProvider>();
      return [
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed:
                _busy ? null : () => _answer(() => provider.accept(duel.id)),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnowtrakRadius.md),
              ),
            ),
            child: const Text('Accept challenge'),
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.sm),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed:
                _busy ? null : () => _answer(() => provider.decline(duel.id)),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              side: BorderSide(color: context.colors.borderStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnowtrakRadius.md),
              ),
            ),
            child: const Text('Decline'),
          ),
        ),
      ];
    }

    if (duel.awaitingAnswerFor(viewerId)) {
      final provider = context.read<DuelProvider>();
      return [
        Center(
          child: TextButton(
            onPressed:
                _busy ? null : () => _answer(() => provider.cancel(duel.id)),
            child: const Text('Cancel challenge'),
          ),
        ),
      ];
    }

    return const [];
  }
}

class _Versus extends StatelessWidget {
  const _Versus({required this.duel, required this.viewerId});

  final Duel duel;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    final mine = duel.valueFor(viewerId);
    final theirs = duel.valueFor(duel.otherPlayer(viewerId));
    return StCard(
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _Side(
              name: 'You',
              value: mine,
              metric: duel.metric,
              leading: duel.winnerId == viewerId,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.sm),
            child: Text(
              'vs',
              style: SnowtrakTypography.labelMedium.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => openUserProfile(
                context,
                duel.otherPlayer(viewerId),
                displayName: duel.otherPlayerName(viewerId),
              ),
              child: _Side(
                name: duel.otherPlayerName(viewerId),
                value: theirs,
                metric: duel.metric,
                leading: duel.winnerId == duel.otherPlayer(viewerId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.value,
    required this.metric,
    required this.leading,
  });

  final String name;
  final double? value;
  final DuelMetric metric;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SnowtrakTypography.labelLarge.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.xs),
        Text(
          // A running duel has no scores yet. An em dash says "not counted
          // yet"; a zero would say "skied nothing", which is a different
          // and usually wrong claim.
          value == null ? '—' : formatMetricValue(metric, value!),
          style: SnowtrakTypography.headlineSmall.copyWith(
            color: leading ? context.colors.success : context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Terms extends StatelessWidget {
  const _Terms({required this.duel});

  final Duel duel;

  @override
  Widget build(BuildContext context) {
    return StCard(
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      child: Column(
        children: [
          _TermRow(label: 'Metric', value: duel.metric.label),
          const SizedBox(height: SnowtrakSpacing.sm),
          _TermRow(label: 'Duration', value: duel.duration.label),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: SnowtrakTypography.labelLarge.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.duel, required this.viewerId});

  final Duel duel;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _text(DateTime.now()),
        textAlign: TextAlign.center,
        style: SnowtrakTypography.bodyMedium.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  String _text(DateTime now) {
    switch (duel.status) {
      case DuelStatus.pending:
        final left = duel.answerWindowAt(now);
        final window = left == null ? '' : ' · ${formatRemaining(left)}';
        return duel.awaitingAnswerFrom(viewerId)
            ? 'Waiting on you$window'
            : 'Waiting on ${duel.otherPlayerName(viewerId)}$window';
      case DuelStatus.active:
        final left = duel.remainingAt(now);
        return left == null ? 'Running' : formatRemaining(left);
      case DuelStatus.finished:
        if (duel.isDraw) return 'Drawn — nobody takes this one';
        return duel.winnerId == viewerId
            ? 'You won'
            : '${duel.otherPlayerName(viewerId)} won';
      case DuelStatus.declined:
        return 'Declined';
      case DuelStatus.cancelled:
        return 'Withdrawn';
      case DuelStatus.expired:
        return 'Expired unanswered';
    }
  }
}
