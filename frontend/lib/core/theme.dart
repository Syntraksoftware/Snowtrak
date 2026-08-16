import 'package:flutter/material.dart';

/// Snowtrak Design System
/// Skiing-focused color palette with cool tones and winter sports energy
class SnowtrakColors {
  // Primary Colors - Cool blue with energy
  static const Color primary = Color(0xFF1E88E5); // Bright blue (skiing/snow)
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Secondary Colors - Winter-inspired
  static const Color secondary = Color(0xFF00ACC1); // Cyan (snow/ice)
  static const Color secondaryDark = Color(0xFF00838F);
  static const Color secondaryLight = Color(0xFF4DD0E1);
  
  // Accent Colors - Energy and excitement
  static const Color accent = Color(0xFFFF6B35); // Warm orange (energy)
  static const Color accentDark = Color(0xFFE53935);
  static const Color accentLight = Color(0xFFFF8A65);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA); // Off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Skiing Activity Type Colors
  static const Color alpine = Color(0xFF1E88E5); // Blue
  static const Color crossCountry = Color(0xFF00ACC1); // Cyan
  static const Color freestyle = Color(0xFFFF6B35); // Orange
  static const Color backcountry = Color(0xFF795548); // Brown
  static const Color snowboard = Color(0xFF9C27B0); // Purple
  
  // Divider and Border
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
}

/// Typography System
class SnowtrakTypography {
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.25,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.5,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  // Metrics (for activity stats)
  static const TextStyle metricLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle metricMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
  );
}

/// Spacing System (8px base unit)
class SnowtrakSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border Radius System
class SnowtrakRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double round = 999.0;
}

/// Elevation/Shadow System
class SnowtrakElevation {
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Snowtrak Theme Configuration
class SnowtrakTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
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
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SnowtrakColors.surface,
        selectedItemColor: SnowtrakColors.primary,
        unselectedItemColor: SnowtrakColors.textTertiary,
        selectedLabelStyle: SnowtrakTypography.labelSmall,
        unselectedLabelStyle: SnowtrakTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
            borderRadius: BorderRadius.circular(SnowtrakRadius.round),
          ),
          textStyle: SnowtrakTypography.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        color: SnowtrakColors.textSecondary,
        size: 24,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
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
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SnowtrakColors.darkSurface,
        selectedItemColor: SnowtrakColors.primaryLight,
        unselectedItemColor: SnowtrakColors.darkTextSecondary,
        selectedLabelStyle: SnowtrakTypography.labelSmall,
        unselectedLabelStyle: SnowtrakTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
            borderRadius: BorderRadius.circular(SnowtrakRadius.round),
          ),
          textStyle: SnowtrakTypography.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        color: SnowtrakColors.darkTextSecondary,
        size: 24,
      ),
    );
  }
}

