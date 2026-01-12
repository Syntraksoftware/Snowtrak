import 'package:flutter/material.dart';

/// Syntrak Design System
/// Skiing-focused color palette with cool tones and winter sports energy
class SyntrakColors {
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
class SyntrakTypography {
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
class SyntrakSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border Radius System
class SyntrakRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double round = 999.0;
}

/// Elevation/Shadow System
class SyntrakElevation {
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

/// Syntrak Theme Configuration
class SyntrakTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: SyntrakColors.primary,
        primaryContainer: SyntrakColors.primaryLight,
        secondary: SyntrakColors.secondary,
        secondaryContainer: SyntrakColors.secondaryLight,
        tertiary: SyntrakColors.accent,
        surface: SyntrakColors.surface,
        surfaceVariant: SyntrakColors.surfaceVariant,
        background: SyntrakColors.background,
        error: SyntrakColors.error,
        onPrimary: SyntrakColors.textOnPrimary,
        onSecondary: SyntrakColors.textOnPrimary,
        onTertiary: SyntrakColors.textOnPrimary,
        onSurface: SyntrakColors.textPrimary,
        onSurfaceVariant: SyntrakColors.textSecondary,
        onBackground: SyntrakColors.textPrimary,
        onError: SyntrakColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: SyntrakColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: SyntrakColors.surface,
        foregroundColor: SyntrakColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: SyntrakTypography.headlineMedium.copyWith(
          color: SyntrakColors.textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: SyntrakColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SyntrakColors.surface,
        selectedItemColor: SyntrakColors.primary,
        unselectedItemColor: SyntrakColors.textTertiary,
        selectedLabelStyle: SyntrakTypography.labelSmall,
        unselectedLabelStyle: SyntrakTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: SyntrakTypography.displayLarge.copyWith(color: SyntrakColors.textPrimary),
        displayMedium: SyntrakTypography.displayMedium.copyWith(color: SyntrakColors.textPrimary),
        displaySmall: SyntrakTypography.displaySmall.copyWith(color: SyntrakColors.textPrimary),
        headlineLarge: SyntrakTypography.headlineLarge.copyWith(color: SyntrakColors.textPrimary),
        headlineMedium: SyntrakTypography.headlineMedium.copyWith(color: SyntrakColors.textPrimary),
        headlineSmall: SyntrakTypography.headlineSmall.copyWith(color: SyntrakColors.textPrimary),
        bodyLarge: SyntrakTypography.bodyLarge.copyWith(color: SyntrakColors.textPrimary),
        bodyMedium: SyntrakTypography.bodyMedium.copyWith(color: SyntrakColors.textSecondary),
        bodySmall: SyntrakTypography.bodySmall.copyWith(color: SyntrakColors.textSecondary),
        labelLarge: SyntrakTypography.labelLarge.copyWith(color: SyntrakColors.textPrimary),
        labelMedium: SyntrakTypography.labelMedium.copyWith(color: SyntrakColors.textSecondary),
        labelSmall: SyntrakTypography.labelSmall.copyWith(color: SyntrakColors.textTertiary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SyntrakColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SyntrakColors.primary,
          foregroundColor: SyntrakColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SyntrakSpacing.lg,
            vertical: SyntrakSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SyntrakRadius.round),
          ),
          textStyle: SyntrakTypography.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        color: SyntrakColors.textSecondary,
        size: 24,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: SyntrakColors.primaryLight,
        primaryContainer: SyntrakColors.primary,
        secondary: SyntrakColors.secondaryLight,
        secondaryContainer: SyntrakColors.secondary,
        tertiary: SyntrakColors.accentLight,
        surface: SyntrakColors.darkSurface,
        surfaceVariant: SyntrakColors.darkSurfaceVariant,
        background: SyntrakColors.darkBackground,
        error: SyntrakColors.error,
        onPrimary: SyntrakColors.textOnPrimary,
        onSecondary: SyntrakColors.textOnPrimary,
        onTertiary: SyntrakColors.textOnPrimary,
        onSurface: SyntrakColors.darkTextPrimary,
        onSurfaceVariant: SyntrakColors.darkTextSecondary,
        onBackground: SyntrakColors.darkTextPrimary,
        onError: SyntrakColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: SyntrakColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: SyntrakColors.darkSurface,
        foregroundColor: SyntrakColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: SyntrakTypography.headlineMedium.copyWith(
          color: SyntrakColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: SyntrakColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SyntrakColors.darkSurface,
        selectedItemColor: SyntrakColors.primaryLight,
        unselectedItemColor: SyntrakColors.darkTextSecondary,
        selectedLabelStyle: SyntrakTypography.labelSmall,
        unselectedLabelStyle: SyntrakTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: SyntrakTypography.displayLarge.copyWith(color: SyntrakColors.darkTextPrimary),
        displayMedium: SyntrakTypography.displayMedium.copyWith(color: SyntrakColors.darkTextPrimary),
        displaySmall: SyntrakTypography.displaySmall.copyWith(color: SyntrakColors.darkTextPrimary),
        headlineLarge: SyntrakTypography.headlineLarge.copyWith(color: SyntrakColors.darkTextPrimary),
        headlineMedium: SyntrakTypography.headlineMedium.copyWith(color: SyntrakColors.darkTextPrimary),
        headlineSmall: SyntrakTypography.headlineSmall.copyWith(color: SyntrakColors.darkTextPrimary),
        bodyLarge: SyntrakTypography.bodyLarge.copyWith(color: SyntrakColors.darkTextPrimary),
        bodyMedium: SyntrakTypography.bodyMedium.copyWith(color: SyntrakColors.darkTextSecondary),
        bodySmall: SyntrakTypography.bodySmall.copyWith(color: SyntrakColors.darkTextSecondary),
        labelLarge: SyntrakTypography.labelLarge.copyWith(color: SyntrakColors.darkTextPrimary),
        labelMedium: SyntrakTypography.labelMedium.copyWith(color: SyntrakColors.darkTextSecondary),
        labelSmall: SyntrakTypography.labelSmall.copyWith(color: SyntrakColors.darkTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SyntrakColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SyntrakColors.primaryLight,
          foregroundColor: SyntrakColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SyntrakSpacing.lg,
            vertical: SyntrakSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SyntrakRadius.round),
          ),
          textStyle: SyntrakTypography.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        color: SyntrakColors.darkTextSecondary,
        size: 24,
      ),
    );
  }
}

