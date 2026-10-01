import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_theme_extension.dart';

/// Central theme definition for SkillSwap.
/// Material 3, seed color, light + dark modes.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF6750A4); // M3 baseline purple
  static const Color _secondarySeed = Color(0xFF0EA5E9); // sky blue accent

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      secondary: _secondarySeed,
      brightness: Brightness.light,
    );
    return _buildTheme(cs);
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      secondary: _secondarySeed,
      brightness: Brightness.dark,
    );
    return _buildTheme(cs);
  }

  // ── Shared builder ────────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme cs) {
    final textTheme = GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            fontSize: 57, fontWeight: FontWeight.w400, color: cs.onSurface),
        displayMedium: TextStyle(
            fontSize: 45, fontWeight: FontWeight.w400, color: cs.onSurface),
        displaySmall: TextStyle(
            fontSize: 36, fontWeight: FontWeight.w400, color: cs.onSurface),
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w600, color: cs.onSurface),
        headlineMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w600, color: cs.onSurface),
        headlineSmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: cs.onSurface),
        titleLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: cs.onSurface),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: cs.onSurface),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: textTheme,
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        color: cs.surface,
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
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
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // FilledButton (same)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: cs.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide(color: cs.outlineVariant),
      ),
      // BottomNavigationBar / NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      // Extensions
      extensions: [CategoryThemeExtension.fromColorScheme(cs)],
      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
      ),
      // Divider
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1),
    );
  }
}
