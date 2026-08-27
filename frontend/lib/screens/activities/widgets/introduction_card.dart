import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/activities/widgets/home_action_row.dart';
import 'package:snowtrak/screens/activities/widgets/home_section_card.dart';
import 'package:snowtrak/screens/activities/widgets/home_section_spacing.dart';
import 'package:snowtrak/screens/activities/widgets/home_selectable_chip.dart';
import 'package:snowtrak/screens/home/home_tab_scope.dart';

enum _IntroAction { record, community, stats }

class IntroductionCard extends StatefulWidget {
  const IntroductionCard({super.key});

  @override
  State<IntroductionCard> createState() => _IntroductionCardState();
}

class _IntroductionCardState extends State<IntroductionCard> {
  _IntroAction _selected = _IntroAction.record;

  void _selectAction(_IntroAction action) {
    setState(() => _selected = action);
    HomeTabScope.selectTabOrNull(context, switch (action) {
      _IntroAction.record => HomeTab.record,
      _IntroAction.community => HomeTab.community,
      _IntroAction.stats => HomeTab.profile,
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionSpacing(
      child: HomeSectionCard(
        icon: Icons.downhill_skiing,
        title: 'New to Snowtrak?',
        subtitle: 'Pick a starting point',
        iconColor: context.colors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: SnowtrakSpacing.xs,
              runSpacing: SnowtrakSpacing.xs,
              children: [
                HomeSelectableChip(
                  label: 'Record',
                  icon: Icons.fiber_manual_record,
                  dense: true,
                  selected: _selected == _IntroAction.record,
                  onTap: () => _selectAction(_IntroAction.record),
                ),
                HomeSelectableChip(
                  label: 'Community',
                  icon: Icons.people_outline,
                  dense: true,
                  selected: _selected == _IntroAction.community,
                  onTap: () => _selectAction(_IntroAction.community),
                ),
                HomeSelectableChip(
                  label: 'Stats',
                  icon: Icons.insights_outlined,
                  dense: true,
                  selected: _selected == _IntroAction.stats,
                  onTap: () => _selectAction(_IntroAction.stats),
                ),
              ],
            ),
            const SizedBox(height: SnowtrakSpacing.sm),
            HomeActionRow(
              title: _actionTitle(_selected),
              subtitle: _actionSubtitle(_selected),
              onTap: () => _selectAction(_selected),
            ),
          ],
        ),
      ),
    );
  }

  String _actionTitle(_IntroAction action) => switch (action) {
        _IntroAction.record => 'Record your first run',
        _IntroAction.community => 'Browse the community feed',
        _IntroAction.stats => 'Open your athlete profile',
      };

  String _actionSubtitle(_IntroAction action) => switch (action) {
        _IntroAction.record => 'Open Map and start tracking',
        _IntroAction.community => 'See what others are skiing',
        _IntroAction.stats => 'View performance and privacy settings',
      };
}
