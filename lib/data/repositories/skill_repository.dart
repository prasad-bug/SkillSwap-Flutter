import '../models/skill.dart';
import '../models/app_user.dart';

/// Filter parameters for skill listing.
class SkillFilter {
  const SkillFilter({
    this.query = '',
    this.category,
    this.level,
    this.availability,
    this.minRating = 0.0,
    this.sortBy = SkillSortBy.popular,
  });

  final String query;
  final SkillCategory? category;
  final SkillLevel? level;
  final AvailabilityStatus? availability;
  final double minRating;
  final SkillSortBy sortBy;

  SkillFilter copyWith({
    String? query,
    SkillCategory? category,
    bool clearCategory = false,
    SkillLevel? level,
    bool clearLevel = false,
    AvailabilityStatus? availability,
    bool clearAvailability = false,
    double? minRating,
    SkillSortBy? sortBy,
  }) {
    return SkillFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      level: clearLevel ? null : (level ?? this.level),
      availability:
          clearAvailability ? null : (availability ?? this.availability),
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SkillSortBy {
  popular,
  rating,
  newest,
  title;

  String get label {
    switch (this) {
      case SkillSortBy.popular:
        return 'Most Popular';
      case SkillSortBy.rating:
        return 'Highest Rated';
      case SkillSortBy.newest:
        return 'Newest';
      case SkillSortBy.title:
        return 'A-Z';
    }
  }
}

/// Abstract interface for skill data operations.
abstract class SkillRepository {
  /// Get all skills (or with filter).
  Future<List<Skill>> getSkills({SkillFilter? filter});

  /// Get a skill by id.
  Future<Skill?> getSkillById(String skillId);

  /// Get skills by owner id.
  Future<List<Skill>> getSkillsByOwner(String ownerId);

  /// Create or update a skill.
  Future<Skill> saveSkill(Skill skill);

  /// Delete a skill by id.
  Future<void> deleteSkill(String skillId);

  /// Get popular skills (top N by rating).
  Future<List<Skill>> getPopularSkills({int limit = 10});

  /// Get owner of skill (user).
  Future<AppUser?> getSkillOwner(String ownerId);

  /// Stream of all skills (for real-time).
  Stream<List<Skill>> watchSkills({SkillFilter? filter});
}
