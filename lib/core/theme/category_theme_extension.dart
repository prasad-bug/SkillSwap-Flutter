import 'package:flutter/material.dart';

/// ThemeExtension that maps SkillCategory → Color pair (background + onBackground).
/// Used for category chips and cards.
@immutable
class CategoryThemeExtension extends ThemeExtension<CategoryThemeExtension> {
  const CategoryThemeExtension({
    required this.techColor,
    required this.musicColor,
    required this.languageColor,
    required this.artColor,
    required this.fitnessColor,
    required this.cookingColor,
    required this.businessColor,
    required this.otherColor,
  });

  final Color techColor;
  final Color musicColor;
  final Color languageColor;
  final Color artColor;
  final Color fitnessColor;
  final Color cookingColor;
  final Color businessColor;
  final Color otherColor;

  /// Build from a ColorScheme so colors stay harmonious with theme.
  factory CategoryThemeExtension.fromColorScheme(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    return CategoryThemeExtension(
      techColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
      musicColor: isDark ? const Color(0xFF3B1F4D) : const Color(0xFFF3E8FF),
      languageColor: isDark ? const Color(0xFF143A2B) : const Color(0xFFD1FAE5),
      artColor: isDark ? const Color(0xFF4D2A1A) : const Color(0xFFFFEDD5),
      fitnessColor: isDark ? const Color(0xFF3A1A2A) : const Color(0xFFFFE4E6),
      cookingColor: isDark ? const Color(0xFF3A2E00) : const Color(0xFFFEF9C3),
      businessColor: isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE0F2FE),
      otherColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
    );
  }

  @override
  CategoryThemeExtension copyWith({
    Color? techColor,
    Color? musicColor,
    Color? languageColor,
    Color? artColor,
    Color? fitnessColor,
    Color? cookingColor,
    Color? businessColor,
    Color? otherColor,
  }) {
    return CategoryThemeExtension(
      techColor: techColor ?? this.techColor,
      musicColor: musicColor ?? this.musicColor,
      languageColor: languageColor ?? this.languageColor,
      artColor: artColor ?? this.artColor,
      fitnessColor: fitnessColor ?? this.fitnessColor,
      cookingColor: cookingColor ?? this.cookingColor,
      businessColor: businessColor ?? this.businessColor,
      otherColor: otherColor ?? this.otherColor,
    );
  }

  @override
  CategoryThemeExtension lerp(
      CategoryThemeExtension? other, double t) {
    if (other is! CategoryThemeExtension) return this;
    return CategoryThemeExtension(
      techColor: Color.lerp(techColor, other.techColor, t)!,
      musicColor: Color.lerp(musicColor, other.musicColor, t)!,
      languageColor: Color.lerp(languageColor, other.languageColor, t)!,
      artColor: Color.lerp(artColor, other.artColor, t)!,
      fitnessColor: Color.lerp(fitnessColor, other.fitnessColor, t)!,
      cookingColor: Color.lerp(cookingColor, other.cookingColor, t)!,
      businessColor: Color.lerp(businessColor, other.businessColor, t)!,
      otherColor: Color.lerp(otherColor, other.otherColor, t)!,
    );
  }

  /// Get color for a category string (matches SkillCategory.name).
  Color colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return techColor;
      case 'music':
        return musicColor;
      case 'language':
        return languageColor;
      case 'art':
        return artColor;
      case 'fitness':
        return fitnessColor;
      case 'cooking':
        return cookingColor;
      case 'business':
        return businessColor;
      default:
        return otherColor;
    }
  }

  /// Icon for a category.
  static IconData iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.computer_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'art':
        return Icons.palette_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'cooking':
        return Icons.restaurant_rounded;
      case 'business':
        return Icons.business_center_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  static CategoryThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<CategoryThemeExtension>()!;
  }
}
