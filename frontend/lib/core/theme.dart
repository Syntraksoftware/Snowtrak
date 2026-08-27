import 'package:flutter/material.dart';

/// Snowtrak Design System
///
/// Tokens mirror the `Core — Colour / Type / Space` collections in
/// `pencil_assets/Snowtrak_DesignSystem.fig` (page `12 layout now`), which is the
/// single source of truth for the product design. Neutral ramp for everything
/// structural; colour only where it carries meaning (status, activity type).
class SnowtrakColors {
  // Neutral ramp — the whole UI is built from this.
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DC);
  static const Color neutral400 = Color(0xFF99A1AF);
  static const Color neutral500 = Color(0xFF6A7282);
  static const Color neutral600 = Color(0xFF4A5565);
  static const Color neutral700 = Color(0xFF364153);
  static const Color neutral800 = Color(0xFF1E2939);
  static const Color neutral900 = Color(0xFF101828);
  static const Color neutral950 = Color(0xFF0A0A0A);

  /// Ink. The brand's one dominant colour: CTAs, active nav, headings.
  static const Color ink = neutral900;

  // Primary = ink. Kept under the old names so existing screens re-skin for free.
  static const Color primary = ink;
  static const Color primaryDark = neutral950;
  static const Color primaryLight = neutral700;

  static const Color secondary = neutral600;
  static const Color secondaryDark = neutral700;
  static const Color secondaryLight = neutral400;

  static const Color accent = ink;
  static const Color accentDark = neutral950;
  static const Color accentLight = neutral700;

  // Surfaces
  static const Color background = neutral50; // surface/subtle — the page
  static const Color surface = neutral0; // surface/page — cards
  static const Color surfaceVariant = neutral100; // surface/tile — chips, tiles
  static const Color surfaceInverse = ink;

  // Text
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textTertiary = neutral500;
  static const Color textQuaternary = neutral400; // captions, unit labels
  static const Color textOnPrimary = neutral0;

  // Status — the only place colour is allowed to mean something
  static const Color success = Color(0xFF00A63E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFFB2C36);
  static const Color info = Color(0xFF2B7FFF);
  static const Color live = Color(0xFF00C950); // "on the mountain now" dot

  // Skiing activity types — muted so they read as data, not decoration
  static const Color alpine = Color(0xFF2B7FFF);
  static const Color crossCountry = Color(0xFF00A63E);
  static const Color freestyle = Color(0xFFB45309);
  static const Color backcountry = Color(0xFF6A7282);
  static const Color snowboard = Color(0xFF7C3AED);

  // Lines
  static const Color divider = neutral100;
  static const Color border = neutral200;
  static const Color borderStrong = neutral300;

  // Dark mode
  static const Color darkBackground = neutral950;
  static const Color darkSurface = Color(0xFF161A2E);
  static const Color darkSurfaceVariant = Color(0xFF20263F);
  static const Color darkTextPrimary = Color(0xFFEEF2F6);
  static const Color darkTextSecondary = Color(0xFFA9B2CC);
  static const Color darkTextTertiary = neutral400;
  static const Color darkTextQuaternary = neutral500;
  static const Color darkDivider = darkSurfaceVariant;
  static const Color darkBorder = Color(0xFF2A3149);
  static const Color darkBorderStrong = Color(0xFF3A4260);

  // Scrim — the wash behind sheets, dialogs, and image overlays. Apply alpha at
  // the call site; this is the base colour, not the finished value.
  static const Color scrim = ink;
  static const Color darkScrim = neutral950;
}

/// Semantic colour roles, resolved against the active theme.
///
/// `SnowtrakColors` above is the *definition* — raw values, compile-time
/// constants. This is what UI code reads, because a `static const` cannot
/// change when the theme does. Screens name a **role**, never a value:
///
/// ```dart
/// Text('...', style: TextStyle(color: context.colors.textSecondary));
/// ```
///
/// Adding a role means touching four places: the field, `light`, `dark`, and
/// `copyWith`, plus a line in `lerp`. A forgotten `lerp` line silently pins
/// that colour to the light value during a theme change — `theme_test.dart`
/// catches exactly that.
///
/// Activity-type colours (`alpine`, `snowboard`, …) deliberately stay on
/// `SnowtrakColors`: they encode data, not chrome, so they read the same in
/// both modes.
@immutable
class SnowtrakPalette extends ThemeExtension<SnowtrakPalette> {
  const SnowtrakPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.textOnPrimary,
    required this.divider,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.live,
    required this.scrim,
  });

  /// Surfaces — the page, cards, and tiles.
  final Color background;
  final Color surface;
  final Color surfaceVariant;

  /// Text, most to least prominent.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;

  /// Text sitting on top of [primary].
  final Color textOnPrimary;

  /// Lines.
  final Color divider;
  final Color border;

  /// A heavier outline, for controls the faint [border] loses.
  final Color borderStrong;

  /// The one dominant colour: CTAs, active nav, headings.
  final Color primary;

  /// Status — the only place colour is allowed to mean something.
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color live;

  /// Base colour for overlays and shadows. Apply alpha at the call site.
  final Color scrim;

  static const SnowtrakPalette light = SnowtrakPalette(
    background: SnowtrakColors.background,
    surface: SnowtrakColors.surface,
    surfaceVariant: SnowtrakColors.surfaceVariant,
    textPrimary: SnowtrakColors.textPrimary,
    textSecondary: SnowtrakColors.textSecondary,
    textTertiary: SnowtrakColors.textTertiary,
    textQuaternary: SnowtrakColors.textQuaternary,
    textOnPrimary: SnowtrakColors.textOnPrimary,
    divider: SnowtrakColors.divider,
    border: SnowtrakColors.border,
    borderStrong: SnowtrakColors.borderStrong,
    primary: SnowtrakColors.ink,
    success: SnowtrakColors.success,
    warning: SnowtrakColors.warning,
    error: SnowtrakColors.error,
    info: SnowtrakColors.info,
    live: SnowtrakColors.live,
    scrim: SnowtrakColors.scrim,
  );

  static const SnowtrakPalette dark = SnowtrakPalette(
    background: SnowtrakColors.darkBackground,
    surface: SnowtrakColors.darkSurface,
    surfaceVariant: SnowtrakColors.darkSurfaceVariant,
    textPrimary: SnowtrakColors.darkTextPrimary,
    textSecondary: SnowtrakColors.darkTextSecondary,
    textTertiary: SnowtrakColors.darkTextTertiary,
    textQuaternary: SnowtrakColors.darkTextQuaternary,
    textOnPrimary: SnowtrakColors.textOnPrimary,
    divider: SnowtrakColors.darkDivider,
    border: SnowtrakColors.darkBorder,
    borderStrong: SnowtrakColors.darkBorderStrong,
    // Ink is the page in dark mode, so the CTA lifts instead of sinking.
    primary: SnowtrakColors.primaryLight,
    success: SnowtrakColors.success,
    warning: SnowtrakColors.warning,
    error: SnowtrakColors.error,
    info: SnowtrakColors.info,
    live: SnowtrakColors.live,
    scrim: SnowtrakColors.darkScrim,
  );

  // ponytail: status colours are shared across modes. Saturated hues on a dark
  // page usually want lightening — tune these five here when dark mode ships.

  @override
  SnowtrakPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuaternary,
    Color? textOnPrimary,
    Color? divider,
    Color? border,
    Color? borderStrong,
    Color? primary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? live,
    Color? scrim,
  }) {
    return SnowtrakPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textQuaternary: textQuaternary ?? this.textQuaternary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      live: live ?? this.live,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  SnowtrakPalette lerp(ThemeExtension<SnowtrakPalette>? other, double t) {
    if (other is! SnowtrakPalette) {
      return this;
    }
    return SnowtrakPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textQuaternary: Color.lerp(textQuaternary, other.textQuaternary, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      live: Color.lerp(live, other.live, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// `context.colors.textSecondary` — the only way UI code should name a colour.
///
/// Falls back to [SnowtrakPalette.light] so a widget built outside a
/// `SnowtrakTheme` (a bare `MaterialApp` in a test, a golden harness) still
/// renders instead of throwing.
extension SnowtrakPaletteContext on BuildContext {
  SnowtrakPalette get colors =>
      Theme.of(this).extension<SnowtrakPalette>() ?? SnowtrakPalette.light;
}

/// Typography System
///
/// Sizes come from `07 · Screens — Home` → `Device/HomeFeed` in the design file,
/// which is the reference screen for the whole app.
///
/// `Core — Type` is Inter-only. Inter is not bundled, so `family` stays null and
/// Flutter falls back to the platform UI face (SF Pro / Roboto) — both are the
/// same grotesque genus as Inter.
// ponytail: no font binary shipped; set `family` + a pubspec font entry if the
// fallback ever drifts too far from the comps.
class SnowtrakTypography {
  static const String? family = null;

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  // Headlines — 22 page title, 20 card hero, 17 card title.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.23,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.2,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.24,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  // Labels — 14 names, 12 meta/actions, 10 nav + unit captions.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.21,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: family,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  /// Uppercase section eyebrow — "YOUR STATISTICS", "NEARBY RESORT".
  static const TextStyle eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.27,
  );

  /// Caption under a metric — "Snow Depth", "Sessions".
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  // Metrics — 26 temperature, 18 stat cell, 17 conditions tile.
  static const TextStyle metricLarge = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.23,
  );

  static const TextStyle metricMedium = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.22,
  );

  static const TextStyle metricSmall = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.24,
  );
}

/// Spacing System — `Core — Space`, a 4px grid.
class SnowtrakSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smd = 12.0;
  static const double md = 16.0;
  static const double lmd = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border Radius System — `Core — Space` radius scale.
class SnowtrakRadius {
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double round = 999.0;
}

/// Elevation/Shadow System
///
/// The design is flat: cards are separated by a hairline border, not a shadow.
/// Only the Record FAB and true overlays lift off the page.
class SnowtrakElevation {
  static const List<BoxShadow> none = [];

  static List<BoxShadow> get sm => const [];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: SnowtrakColors.ink.withOpacity(0.06),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: SnowtrakColors.ink.withOpacity(0.10),
      blurRadius: 15,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: SnowtrakColors.ink.withOpacity(0.10),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: SnowtrakColors.ink.withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
}

/// Snowtrak Theme Configuration
class SnowtrakTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: SnowtrakColors.primary,
        primaryContainer: SnowtrakColors.primaryLight,
        secondary: SnowtrakColors.secondary,
        secondaryContainer: SnowtrakColors.secondaryLight,
        tertiary: SnowtrakColors.accent,
        surface: SnowtrakColors.surface,
        surfaceVariant: SnowtrakColors.surfaceVariant,
        background: SnowtrakColors.background,
        error: SnowtrakColors.error,
        onPrimary: SnowtrakColors.textOnPrimary,
        onSecondary: SnowtrakColors.textOnPrimary,
        onTertiary: SnowtrakColors.textOnPrimary,
        onSurface: SnowtrakColors.textPrimary,
        onSurfaceVariant: SnowtrakColors.textSecondary,
        onBackground: SnowtrakColors.textPrimary,
        onError: SnowtrakColors.textOnPrimary,
      ),
      extensions: const [SnowtrakPalette.light],
      scaffoldBackgroundColor: SnowtrakColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: SnowtrakColors.surface,
        foregroundColor: SnowtrakColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: SnowtrakTypography.headlineMedium.copyWith(
          color: SnowtrakColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: SnowtrakColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          side: const BorderSide(color: SnowtrakColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SnowtrakColors.surface,
        selectedItemColor: SnowtrakColors.ink,
        unselectedItemColor: SnowtrakColors.neutral400,
        selectedLabelStyle: SnowtrakTypography.labelSmall,
        unselectedLabelStyle: SnowtrakTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: SnowtrakTypography.displayLarge.copyWith(color: SnowtrakColors.textPrimary),
        displayMedium: SnowtrakTypography.displayMedium.copyWith(color: SnowtrakColors.textPrimary),
        displaySmall: SnowtrakTypography.displaySmall.copyWith(color: SnowtrakColors.textPrimary),
        headlineLarge: SnowtrakTypography.headlineLarge.copyWith(color: SnowtrakColors.textPrimary),
        headlineMedium: SnowtrakTypography.headlineMedium.copyWith(color: SnowtrakColors.textPrimary),
        headlineSmall: SnowtrakTypography.headlineSmall.copyWith(color: SnowtrakColors.textPrimary),
        bodyLarge: SnowtrakTypography.bodyLarge.copyWith(color: SnowtrakColors.textPrimary),
        bodyMedium: SnowtrakTypography.bodyMedium.copyWith(color: SnowtrakColors.textSecondary),
        bodySmall: SnowtrakTypography.bodySmall.copyWith(color: SnowtrakColors.textSecondary),
        labelLarge: SnowtrakTypography.labelLarge.copyWith(color: SnowtrakColors.textPrimary),
        labelMedium: SnowtrakTypography.labelMedium.copyWith(color: SnowtrakColors.textSecondary),
        labelSmall: SnowtrakTypography.labelSmall.copyWith(color: SnowtrakColors.textTertiary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SnowtrakColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnowtrakSpacing.md,
          vertical: SnowtrakSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SnowtrakColors.primary,
          foregroundColor: SnowtrakColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SnowtrakSpacing.lg,
            vertical: SnowtrakSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnowtrakRadius.md),
          ),
          textStyle: SnowtrakTypography.labelLarge,
        ),
      ),
      iconTheme: const IconThemeData(
        color: SnowtrakColors.textSecondary,
        size: 22,
      ),
      dividerTheme: const DividerThemeData(
        color: SnowtrakColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: SnowtrakColors.primaryLight,
        primaryContainer: SnowtrakColors.primary,
        secondary: SnowtrakColors.secondaryLight,
        secondaryContainer: SnowtrakColors.secondary,
        tertiary: SnowtrakColors.accentLight,
        surface: SnowtrakColors.darkSurface,
        surfaceVariant: SnowtrakColors.darkSurfaceVariant,
        background: SnowtrakColors.darkBackground,
        error: SnowtrakColors.error,
        onPrimary: SnowtrakColors.textOnPrimary,
        onSecondary: SnowtrakColors.textOnPrimary,
        onTertiary: SnowtrakColors.textOnPrimary,
        onSurface: SnowtrakColors.darkTextPrimary,
        onSurfaceVariant: SnowtrakColors.darkTextSecondary,
        onBackground: SnowtrakColors.darkTextPrimary,
        onError: SnowtrakColors.textOnPrimary,
      ),
      extensions: const [SnowtrakPalette.dark],
      scaffoldBackgroundColor: SnowtrakColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: SnowtrakColors.darkSurface,
        foregroundColor: SnowtrakColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: SnowtrakTypography.headlineMedium.copyWith(
          color: SnowtrakColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: SnowtrakColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          side: const BorderSide(color: SnowtrakColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SnowtrakColors.darkSurface,
        selectedItemColor: SnowtrakColors.primaryLight,
        unselectedItemColor: SnowtrakColors.darkTextSecondary,
        selectedLabelStyle: SnowtrakTypography.labelSmall,
        unselectedLabelStyle: SnowtrakTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: SnowtrakTypography.displayLarge.copyWith(color: SnowtrakColors.darkTextPrimary),
        displayMedium: SnowtrakTypography.displayMedium.copyWith(color: SnowtrakColors.darkTextPrimary),
        displaySmall: SnowtrakTypography.displaySmall.copyWith(color: SnowtrakColors.darkTextPrimary),
        headlineLarge: SnowtrakTypography.headlineLarge.copyWith(color: SnowtrakColors.darkTextPrimary),
        headlineMedium: SnowtrakTypography.headlineMedium.copyWith(color: SnowtrakColors.darkTextPrimary),
        headlineSmall: SnowtrakTypography.headlineSmall.copyWith(color: SnowtrakColors.darkTextPrimary),
        bodyLarge: SnowtrakTypography.bodyLarge.copyWith(color: SnowtrakColors.darkTextPrimary),
        bodyMedium: SnowtrakTypography.bodyMedium.copyWith(color: SnowtrakColors.darkTextSecondary),
        bodySmall: SnowtrakTypography.bodySmall.copyWith(color: SnowtrakColors.darkTextSecondary),
        labelLarge: SnowtrakTypography.labelLarge.copyWith(color: SnowtrakColors.darkTextPrimary),
        labelMedium: SnowtrakTypography.labelMedium.copyWith(color: SnowtrakColors.darkTextSecondary),
        labelSmall: SnowtrakTypography.labelSmall.copyWith(color: SnowtrakColors.darkTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SnowtrakColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnowtrakRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnowtrakSpacing.md,
          vertical: SnowtrakSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SnowtrakColors.primaryLight,
          foregroundColor: SnowtrakColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SnowtrakSpacing.lg,
            vertical: SnowtrakSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnowtrakRadius.md),
          ),
          textStyle: SnowtrakTypography.labelLarge,
        ),
      ),
      iconTheme: const IconThemeData(
        color: SnowtrakColors.darkTextSecondary,
        size: 24,
      ),
    );
  }
}

