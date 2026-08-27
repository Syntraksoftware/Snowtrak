import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/ski_trail.dart';

Future<void> showTrailsDifficultyPicker(
  BuildContext context, {
  required TrailDifficulty? selected,
  required void Function(TrailDifficulty?) onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: SnowtrakColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(SnowtrakRadius.xl)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: SnowtrakSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SnowtrakColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          const Text(
            'Select Difficulty',
            style: SnowtrakTypography.headlineSmall,
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('All Difficulties'),
            selected: selected == null,
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          ...TrailDifficulty.values.map((d) => ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(d.color),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      d.icon,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                title: Text(d.displayName),
                selected: selected == d,
                onTap: () {
                  onSelected(d);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: SnowtrakSpacing.lg),
        ],
      ),
    ),
  );
}

Future<void> showTrailsCountryPicker(
  BuildContext context, {
  required String? selected,
  required List<String> countries,
  required void Function(String?) onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: SnowtrakColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(SnowtrakRadius.xl)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: SnowtrakSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SnowtrakColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          const Text(
            'Select Country',
            style: SnowtrakTypography.headlineSmall,
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('All Countries'),
            selected: selected == null,
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          ...countries.map((c) => ListTile(
                leading: const Icon(Icons.place),
                title: Text(c),
                selected: selected == c,
                onTap: () {
                  onSelected(c);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: SnowtrakSpacing.lg),
        ],
      ),
    ),
  );
}
