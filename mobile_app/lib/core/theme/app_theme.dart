import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0058BE);
  static const primaryContainer = Color(0xFF2170E4);
  static const surface = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEEF1FB);
  static const surfaceContainer = Color(0xFFE4E8F5);
  static const surfaceContainerHigh = Color(0xFFD9DCF0);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF3D5068);
  static const outline = Color(0xFF8A9ABB);
  static const tertiary = Color(0xFF924700);
  static const error = Color(0xFFB3261E);
  static const onPrimary = Color(0xFFFFFFFF);

  static const primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const heroGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.primaryContainer,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.surfaceContainerLow,
      onSecondaryContainer: AppColors.onSurface,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: const Color(0xFFFFDCC2),
      onTertiaryContainer: const Color(0xFF301400),
      error: AppColors.error,
      onError: AppColors.onPrimary,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: const Color(0xFF8A9ABB),
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: const Color(0xFFCDD1E8),
      inverseSurface: AppColors.onSurface,
      onInverseSurface: AppColors.surface,
      inversePrimary: const Color(0xFFABC7FF),
      shadow: AppColors.onSurface,
      scrim: AppColors.onSurface,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.manrope(
          fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.2),
      displayMedium: GoogleFonts.manrope(
          fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.2),
      displaySmall: GoogleFonts.manrope(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.2),
      headlineLarge: GoogleFonts.manrope(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.3),
      headlineMedium: GoogleFonts.manrope(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.3),
      headlineSmall: GoogleFonts.manrope(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.3),
      titleLarge: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.4),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.4),
      titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.4),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.5),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.5),
      bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
          height: 1.5),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.4),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.4),
      labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
          height: 1.4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant);
        }),
        elevation: 0,
        height: 64,
      ),
      dividerTheme: const DividerThemeData(color: Colors.transparent, space: 0),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
