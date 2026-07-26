import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch `DESIGN.md` — Clinical Serenity (Deep Calming Teal).
abstract final class LulunaColors {
  static const primary = Color(0xFF00434B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF005C67);
  static const onPrimaryContainer = Color(0xFF8DD2DF);
  static const secondary = Color(0xFF006970);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF9DF0F8);
  static const onSecondaryContainer = Color(0xFF026F77);
  static const tertiary = Color(0xFF343E3F);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF4A5556);
  static const onTertiaryContainer = Color(0xFFBEC9CA);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const surface = Color(0xFFF8F9F9);
  static const onSurface = Color(0xFF191C1C);
  static const onSurfaceVariant = Color(0xFF3F484A);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F4);
  static const surfaceContainer = Color(0xFFEDEEEE);
  static const surfaceContainerHigh = Color(0xFFE7E8E8);
  static const surfaceContainerHighest = Color(0xFFE1E3E3);
  static const outline = Color(0xFF6F797B);
  static const outlineVariant = Color(0xFFBFC8CA);
  static const syncBanner = Color(0xFFD4E8EB);
  static const badgeBg = Color(0xFFE7E9FF);
  static const badgeFg = Color(0xFF3F51B5);
  static const crisisRed = Color(0xFFE53935);
}

abstract final class LulunaTheme {
  static ColorScheme get _scheme => const ColorScheme(
        brightness: Brightness.light,
        primary: LulunaColors.primary,
        onPrimary: LulunaColors.onPrimary,
        primaryContainer: LulunaColors.primaryContainer,
        onPrimaryContainer: LulunaColors.onPrimaryContainer,
        secondary: LulunaColors.secondary,
        onSecondary: LulunaColors.onSecondary,
        secondaryContainer: LulunaColors.secondaryContainer,
        onSecondaryContainer: LulunaColors.onSecondaryContainer,
        tertiary: LulunaColors.tertiary,
        onTertiary: LulunaColors.onTertiary,
        tertiaryContainer: LulunaColors.tertiaryContainer,
        onTertiaryContainer: LulunaColors.onTertiaryContainer,
        error: LulunaColors.error,
        onError: LulunaColors.onError,
        errorContainer: LulunaColors.errorContainer,
        onErrorContainer: LulunaColors.onErrorContainer,
        surface: LulunaColors.surface,
        onSurface: LulunaColors.onSurface,
        onSurfaceVariant: LulunaColors.onSurfaceVariant,
        outline: LulunaColors.outline,
        outlineVariant: LulunaColors.outlineVariant,
        surfaceContainerLowest: LulunaColors.surfaceContainerLowest,
        surfaceContainerLow: LulunaColors.surfaceContainerLow,
        surfaceContainer: LulunaColors.surfaceContainer,
        surfaceContainerHigh: LulunaColors.surfaceContainerHigh,
        surfaceContainerHighest: LulunaColors.surfaceContainerHighest,
      );

  static ThemeData light() {
    final scheme = _scheme;
    final manrope = GoogleFonts.manropeTextTheme();
    final inter = GoogleFonts.interTextTheme();

    final textTheme = inter.copyWith(
      displaySmall: manrope.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        color: LulunaColors.primary,
      ),
      headlineLarge: manrope.headlineLarge?.copyWith(
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 26,
        color: LulunaColors.onSurface,
      ),
      headlineMedium: manrope.headlineMedium?.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: LulunaColors.onSurface,
      ),
      headlineSmall: manrope.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: LulunaColors.onSurface,
      ),
      titleLarge: manrope.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: LulunaColors.onSurface,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: LulunaColors.onSurface,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 18,
        height: 28 / 18,
        color: LulunaColors.onSurface,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 16,
        height: 24 / 16,
        color: LulunaColors.onSurface,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        color: LulunaColors.onSurfaceVariant,
      ),
      labelLarge: inter.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: LulunaColors.onSurface,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.01 * 14,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
        color: LulunaColors.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LulunaColors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: LulunaColors.surface.withValues(alpha: 0.85),
        foregroundColor: LulunaColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: manrope.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LulunaColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: LulunaColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LulunaColors.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LulunaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LulunaColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LulunaColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: LulunaColors.primary,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: LulunaColors.onSurfaceVariant),
        hintStyle: const TextStyle(color: LulunaColors.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LulunaColors.primaryContainer,
          foregroundColor: LulunaColors.onPrimary,
          minimumSize: const Size.fromHeight(56),
          elevation: 2,
          shadowColor: LulunaColors.primary.withValues(alpha: 0.25),
          textStyle: manrope.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LulunaColors.onSurface,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: LulunaColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LulunaColors.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LulunaColors.secondaryContainer,
        labelStyle: TextStyle(
          color: LulunaColors.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LulunaColors.surface,
        indicatorColor: LulunaColors.secondaryContainer.withValues(alpha: 0.55),
        elevation: 8,
        shadowColor: LulunaColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? LulunaColors.primary
                : LulunaColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? LulunaColors.primary
                : LulunaColors.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: LulunaColors.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
