import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the rule in `CLAUDE.md` and `docs/frontend_design_system.md`:
/// UI code names a role, never a value.
///
/// These read source rather than render widgets, because the thing being
/// prevented is a line of code, not a pixel. A rule that only lives in a
/// document gets followed until someone is in a hurry; this one fails the
/// build.
///
/// When one of these trips, the fix is almost never to widen the allowlist.
/// It is to use `context.colors.<role>`, or -- if no role fits -- to say so and
/// add one to `SnowtrakPalette`, which is a design-system change.
void main() {
  final lib = Directory('lib');

  /// Files allowed to name a raw colour value, and why. Matches the three
  /// exceptions in CLAUDE.md.
  const hexAllowed = <String, String>{
    'lib/core/theme.dart': 'the token definition itself',
    'lib/ui/liquid/auth_social_button.dart':
        "Google's brand guidelines fix the four G colours",
    'lib/core/logging/app_logger.dart': 'developer-only debug overlay',
  };

  /// The only Material colour that is not a colour.
  const materialAllowed = {'transparent'};

  /// Semantic roles. Reading one of these off `SnowtrakColors` outside
  /// `theme.dart` is the subtle failure: right role, wrong layer. It renders
  /// correctly today and silently wrong under a theme change, because a
  /// `static const` is fixed at compile time.
  const paletteRoles = {
    'background', 'surface', 'surfaceVariant',
    'textPrimary', 'textSecondary', 'textTertiary', 'textQuaternary',
    'textOnPrimary', 'divider', 'border', 'borderStrong', 'primary',
    'success', 'warning', 'error', 'info', 'live', 'scrim',
  };

  /// Static data that happens to be typed as a role. GroupChallengeItem's badge
  /// says which challenge it is, the way an activity type does, so it belongs
  /// on `SnowtrakColors` and cannot read a context anyway.
  const roleAllowed = <String>{
    'lib/screens/groups/active_tab_widgets.dart',
  };

  List<File> dartFiles() => lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.endsWith('.mocks.dart'))
      .toList();

  /// Walks every line so a failure can name the exact site. A count would say
  /// something broke; a location says what to open.
  List<String> scan(
    RegExp pattern,
    bool Function(String path, RegExpMatch match) isViolation,
  ) {
    final hits = <String>[];
    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in pattern.allMatches(lines[i])) {
          if (isViolation(file.path, match)) {
            hits.add('${file.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
    }
    return hits;
  }

  test('no raw hex outside the token layer', () {
    final hits = scan(
      RegExp(r'Color\(0x[0-9a-fA-F]{6,8}\)'),
      (path, _) => !hexAllowed.containsKey(path),
    );
    expect(
      hits,
      isEmpty,
      reason: 'A literal colour in UI code cannot follow the theme.\n'
          'Use context.colors.<role>. If no role fits, add one to '
          'SnowtrakPalette rather than inventing a hex.\n'
          'Only these may hold raw values: ${hexAllowed.keys.join(", ")}.\n\n'
          '${hits.join("\n")}',
    );
  });

  test('no Material colours except transparent', () {
    final hits = scan(
      RegExp(r'(?<![\w.])Colors\.(\w+)'),
      (_, m) => !materialAllowed.contains(m.group(1)),
    );
    expect(
      hits,
      isEmpty,
      reason: "Material's ramp is not this app's ramp -- its grey is a pure "
          'neutral, ours is blue-tinted -- so these read off-system in every '
          'theme.\n'
          'Map by role, not by nearest hex: grey on text is textSecondary or '
          'textTertiary, grey on a line is divider or border, white behind a '
          'card is surface, white on a filled control is textOnPrimary.\n'
          'Colors.transparent is fine; it is the absence of paint.\n\n'
          '${hits.join("\n")}',
    );
  });

  test('UI code reads roles from the theme, not from constants', () {
    final hits = scan(
      RegExp(r'SnowtrakColors\.(\w+)'),
      (path, m) =>
          path != 'lib/core/theme.dart' &&
          !roleAllowed.contains(path) &&
          paletteRoles.contains(m.group(1)),
    );
    expect(
      hits,
      isEmpty,
      reason: 'Right role, wrong layer. SnowtrakColors is a compile-time '
          'constant, so it cannot answer a theme change -- this renders '
          'correctly today and silently wrong the moment dark mode is on.\n'
          'Read context.colors.<role> instead.\n\n'
          '${hits.join("\n")}',
    );
  });

  test('every widget that reads the palette imports it', () {
    final hits = <String>[];
    for (final file in dartFiles()) {
      final source = file.readAsStringSync();
      if (source.contains('context.colors') &&
          !source.contains("import 'package:snowtrak/core/theme.dart'") &&
          file.path != 'lib/core/theme.dart') {
        hits.add(file.path);
      }
    }
    expect(
      hits,
      isEmpty,
      reason: 'context.colors comes from an extension in core/theme.dart, so a '
          'file using it without the import will not compile.\n\n'
          '${hits.join("\n")}',
    );
  });
}
