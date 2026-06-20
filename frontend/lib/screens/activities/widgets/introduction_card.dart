import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/activities/widgets/home_action_row.dart';
import 'package:syntrak/screens/activities/widgets/home_section_card.dart';
import 'package:syntrak/screens/activities/widgets/home_section_spacing.dart';
import 'package:syntrak/screens/activities/widgets/home_selectable_chip.dart';
import 'package:syntrak/screens/home/home_tab_scope.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

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
      _IntroAction.record => 0,
      _IntroAction.community => 1,
      _IntroAction.stats => 4,
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionSpacing(
      child: HomeSectionCard(
        icon: Icons.downhill_skiing,
        title: 'New to Snowtrak?',
        subtitle: 'Pick a starting point',
        iconColor: SnowtrakAuthTheme.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: SyntrakSpacing.xs,
              runSpacing: SyntrakSpacing.xs,
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
            const SizedBox(height: SyntrakSpacing.sm),
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
