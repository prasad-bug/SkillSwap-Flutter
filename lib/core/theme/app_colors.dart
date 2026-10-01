import 'package:flutter/material.dart';

/// Design tokens for SkillSwap application based on approved Stitch design.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF422EC2);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF5B4BDB);
  static const Color onPrimaryContainer = Color(0xFFE0DBFF);
  static const Color primaryFixed = Color(0xFFE4DFFF);

  // Secondary palette (teal)
  static const Color secondary = Color(0xFF006B5F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF6DF5E1);
  static const Color onSecondaryContainer = Color(0xFF006F64);

  // Tertiary palette (amber / ratings)
  static const Color tertiary = Color(0xFF6A4200);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF8B5700);
  static const Color onTertiaryContainer = Color(0xFFFFDDB3);

  // Surface & containers
  static const Color surface = Color(0xFFF8F9FF);
  static const Color background = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // Content colors
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF474554);

  // Outlines
  static const Color outline = Color(0xFF787586);
  static const Color outlineVariant = Color(0xFFC8C4D7);

  // Errors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
}
