import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/theme.dart';

/// Every role, paired with its reader. Adding a field to [SnowtrakPalette]
/// means adding a line here — that is the point of the list.
final Map<String, Color Function(SnowtrakPalette)> _roles = {
  'background': (p) => p.background,
  'surface': (p) => p.surface,
  'surfaceVariant': (p) => p.surfaceVariant,
  'textPrimary': (p) => p.textPrimary,
  'textSecondary': (p) => p.textSecondary,
  'textTertiary': (p) => p.textTertiary,
  'textQuaternary': (p) => p.textQuaternary,
  'textOnPrimary': (p) => p.textOnPrimary,
  'divider': (p) => p.divider,
  'border': (p) => p.border,
  'primary': (p) => p.primary,
  'success': (p) => p.success,
  'warning': (p) => p.warning,
  'error': (p) => p.error,
  'info': (p) => p.info,
  'live': (p) => p.live,
  'scrim': (p) => p.scrim,
};

void main() {
  group('SnowtrakPalette.lerp', () {
    // 17 near-identical lines is exactly where a copy-paste lands on the wrong
    // field. At the endpoints lerp must reproduce each palette precisely.
    test('t=1 reproduces dark, role by role', () {
      final result = SnowtrakPalette.light.lerp(SnowtrakPalette.dark, 1.0);
      for (final entry in _roles.entries) {
        expect(
          entry.value(result),
          entry.value(SnowtrakPalette.dark),
          reason: '${entry.key} does not resolve to its dark value at t=1',
        );
      }
    });

    test('t=0 reproduces light, role by role', () {
      final result = SnowtrakPalette.light.lerp(SnowtrakPalette.dark, 0.0);
      for (final entry in _roles.entries) {
        expect(
          entry.value(result),
          entry.value(SnowtrakPalette.light),
          reason: '${entry.key} does not resolve to its light value at t=0',
        );
      }
    });

    test('a foreign extension leaves the palette untouched', () {
      expect(SnowtrakPalette.light.lerp(null, 0.5), SnowtrakPalette.light);
    });
  });

  group('theme wiring', () {
    test('both themes carry a palette', () {
      expect(
        SnowtrakTheme.lightTheme.extension<SnowtrakPalette>(),
        SnowtrakPalette.light,
      );
      expect(
        SnowtrakTheme.darkTheme.extension<SnowtrakPalette>(),
        SnowtrakPalette.dark,
      );
    });

    // Roles that must not read the same in both modes, or dark mode is a no-op
    // for anything painted with them.
    test('surfaces and text invert between modes', () {
      for (final name in const [
        'background',
        'surface',
        'surfaceVariant',
        'textPrimary',
        'textSecondary',
        'divider',
        'border',
      ]) {
        expect(
          _roles[name]!(SnowtrakPalette.light),
          isNot(_roles[name]!(SnowtrakPalette.dark)),
          reason: '$name is identical in light and dark',
        );
      }
    });
  });

  testWidgets('context.colors follows the active theme', (tester) async {
    late SnowtrakPalette seen;

    Future<void> pumpWith(ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              seen = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // MaterialApp animates theme swaps, so the first frame still reads the
      // outgoing palette. Settle before asserting.
      await tester.pumpAndSettle();
    }

    await pumpWith(SnowtrakTheme.lightTheme);
    expect(seen.background, SnowtrakColors.background);

    await pumpWith(SnowtrakTheme.darkTheme);
    expect(seen.background, SnowtrakColors.darkBackground);
  });

  testWidgets('falls back to light outside a Snowtrak theme', (tester) async {
    late SnowtrakPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            seen = context.colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen, SnowtrakPalette.light);
  });
}
