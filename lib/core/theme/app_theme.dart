import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'category_theme_extension.dart';

/// Central theme definition for SkillSwap based on approved Stitch design tokens.
class AppTheme {
  AppTheme._();

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    primaryFixed: AppColors.primaryFixed,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryFixed,
    onPrimary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondaryContainer,
    onSecondary: AppColors.onSecondaryContainer,
    secondaryContainer: AppColors.secondary,
    onSecondaryContainer: AppColors.secondaryContainer,
    tertiary: AppColors.tertiaryContainer,
    onTertiary: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    surface: Color(0xFF131318),
    onSurface: Color(0xFFE4E1EC),
    surfaceContainerLowest: Color(0xFF0E0E13),
    surfaceContainerLow: Color(0xFF1B1B21),
    surfaceContainer: Color(0xFF1F1F25),
    surfaceContainerHigh: Color(0xFF2A2930),
    surfaceContainerHighest: Color(0xFF35343B),
    onSurfaceVariant: Color(0xFFC8C4D7),
    outline: AppColors.outline,
    outlineVariant: Color(0xFF474554),
  );

  static ThemeData get light => _buildTheme(lightColorScheme);
  static ThemeData get dark => _buildTheme(darkColorScheme);

  static ThemeData _buildTheme(ColorScheme cs) {
    // Plus Jakarta Sans for headline/title styles, Inter for body/label styles
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64, // -0.02em
        color: cs.onSurface,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        height: 34 / 26,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: cs.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.24, // 0.02em
        color: cs.onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.33, // 0.03em
        color: cs.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      // Cards: radius 16, color surfaceContainerLowest (white in light mode)
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5), width: 1),
        ),
        color: cs.surfaceContainerLowest,
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: cs.outlineVariant),
          foregroundColor: cs.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Chip (badge/chip full radius)
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      // BottomNavigationBar / NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        indicatorColor: cs.primaryContainer.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      // Extensions
      extensions: [CategoryThemeExtension.fromColorScheme(cs)],
      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),
    );
  }
}
