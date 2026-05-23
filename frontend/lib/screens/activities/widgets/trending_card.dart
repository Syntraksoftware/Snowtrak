import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/activities/widgets/home_action_row.dart';
import 'package:syntrak/screens/activities/widgets/home_section_card.dart';
import 'package:syntrak/screens/activities/widgets/home_section_spacing.dart';
import 'package:syntrak/screens/home/home_tab_scope.dart';
import 'package:syntrak/ui/liquid/auth_primary_button.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

class TrendingCard extends StatefulWidget {
  const TrendingCard({super.key});

  @override
  State<TrendingCard> createState() => _TrendingCardState();
}

class _TrendingCardState extends State<TrendingCard> {
  int _selectedIndex = 0;

  static const _items = [
    _TrendingItem(
      title: 'Powder day at Whistler',
      subtitle: '42 athletes posted runs today',
    ),
    _TrendingItem(
      title: '100K vertical February',
      subtitle: 'Challenge · 128 joined',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeSectionSpacing(
      child: HomeSectionCard(
        icon: Icons.trending_up,
        title: 'Trending now',
        subtitle: 'Tap to preview, explore below',
        iconColor: SnowtrakAuthTheme.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(height: SyntrakSpacing.xs),
              HomeActionRow(
                title: _items[i].title,
                subtitle: _items[i].subtitle,
                icon: _selectedIndex == i
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            ],
            const SizedBox(height: SyntrakSpacing.sm),
            AuthPrimaryButton(
              label: 'Explore community',
              onPressed: () => HomeTabScope.selectTabOrNull(context, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingItem {
  const _TrendingItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
