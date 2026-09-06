import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/providers/duel_provider.dart';
import 'package:snowtrak/screens/leaderboard/duel_detail_screen.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Pushes the terms sheet for challenging [opponentId].
Future<void> openDuelTerms(
  BuildContext context, {
  required String opponentId,
  required String opponentName,
}) async {
  if (opponentId.trim().isEmpty) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => DuelTermsScreen(
        opponentId: opponentId,
        opponentName: opponentName,
      ),
    ),
  );
}

/// Picking what a duel measures and how long it runs.
///
/// It does not ask when the duel starts, and cannot: the window opens when
/// the opponent accepts. Offering a start date here would be offering a
/// choice the server refuses to honour.
class DuelTermsScreen extends StatefulWidget {
  const DuelTermsScreen({
    super.key,
    required this.opponentId,
    required this.opponentName,
  });

  final String opponentId;
  final String opponentName;

  @override
  State<DuelTermsScreen> createState() => _DuelTermsScreenState();
}

class _DuelTermsScreenState extends State<DuelTermsScreen> {
  DuelMetric _metric = DuelMetric.vertical;
  DuelDuration _duration = DuelDuration.week;
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    final result = await context.read<DuelProvider>().challenge(
          opponentId: widget.opponentId,
          metric: _metric,
          duration: _duration,
        );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case AppSuccess(:final value):
        Navigator.of(context).pop();
        await openDuel(context, value.id);
      case AppFailure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Set challenge terms'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SnowtrakSpacing.md),
                children: [
                  Text(
                    'Challenging ${widget.opponentName}',
                    style: SnowtrakTypography.headlineSmall.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SnowtrakSpacing.lg),
                  const _SectionLabel('Winning metric'),
                  for (final option in DuelMetric.values)
                    _OptionTile(
                      title: option.label,
                      subtitle: option.blurb,
                      selected: option == _metric,
                      onTap: () => setState(() => _metric = option),
                    ),
                  const SizedBox(height: SnowtrakSpacing.lg),
                  const _SectionLabel('Battle duration'),
                  for (final option in DuelDuration.values)
                    _OptionTile(
                      title: option.label,
                      subtitle: option.blurb,
                      selected: option == _duration,
                      onTap: () => setState(() => _duration = option),
                    ),
                  const SizedBox(height: SnowtrakSpacing.smd),
                  Text(
                    'The clock starts when they accept. Nothing you have '
                    'already skied counts.',
                    style: SnowtrakTypography.bodySmall.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SnowtrakSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SnowtrakRadius.md),
                    ),
                  ),
                  child: Text(_sending ? 'Sending…' : 'Send challenge'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SnowtrakSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: SnowtrakTypography.labelSmall.copyWith(
          color: context.colors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SnowtrakSpacing.sm),
      child: StCard(
        onTap: onTap,
        padding: const EdgeInsets.all(SnowtrakSpacing.md),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected
                  ? context.colors.primary
                  : context.colors.textQuaternary,
            ),
            const SizedBox(width: SnowtrakSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SnowtrakTypography.labelLarge.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: SnowtrakTypography.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
