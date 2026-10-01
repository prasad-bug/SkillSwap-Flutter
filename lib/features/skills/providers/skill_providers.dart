import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/skill.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../core/constants/app_constants.dart';

// ─── Filter state notifier ───────────────────────────────────────────────────

class SkillFilterNotifier extends Notifier<SkillFilter> {
  @override
  SkillFilter build() => const SkillFilter();

  void setQuery(String query) =>
      state = state.copyWith(query: query);

  void setCategory(SkillCategory? cat) =>
      state = state.copyWith(category: cat, clearCategory: cat == null);

  void setLevel(SkillLevel? level) =>
      state = state.copyWith(level: level, clearLevel: level == null);

  void setAvailability(AvailabilityStatus? a) =>
      state = state.copyWith(availability: a, clearAvailability: a == null);

  void setMinRating(double r) =>
      state = state.copyWith(minRating: r);

  void setSortBy(SkillSortBy sortBy) =>
      state = state.copyWith(sortBy: sortBy);

  void clearFilters() =>
      state = const SkillFilter();

  void setFilter(SkillFilter filter) =>
      state = filter;

  bool get hasActiveFilters =>
      state.query.isNotEmpty ||
      state.category != null ||
      state.level != null ||
      state.availability != null ||
      state.minRating > 0;
}

final skillFilterProvider =
    NotifierProvider<SkillFilterNotifier, SkillFilter>(() {
  return SkillFilterNotifier();
});

// ─── Skills list provider (with debounce for search) ─────────────────────────

final skillsProvider = FutureProvider<List<Skill>>((ref) async {
  final filter = ref.watch(skillFilterProvider);
  // Debounce search queries
  if (filter.query.isNotEmpty) {
    await Future.delayed(
        const Duration(milliseconds: AppConstants.searchDebounceMs));
    // Check if query changed during the wait (cancellation via ref invalidation)
  }
  final repo = ref.watch(skillRepositoryProvider);
  return repo.getSkills(filter: filter);
});

// ─── Single skill provider ────────────────────────────────────────────────────

final skillByIdProvider =
    FutureProvider.family<Skill?, String>((ref, skillId) async {
  return ref.watch(skillRepositoryProvider).getSkillById(skillId);
});

// ─── Skill owner provider ─────────────────────────────────────────────────────

final skillOwnerProvider =
    FutureProvider.family<dynamic, String>((ref, ownerId) async {
  return ref.watch(userRepositoryProvider).getUserById(ownerId);
});

// ─── Ratings for a skill ─────────────────────────────────────────────────────

final skillRatingsProvider =
    FutureProvider.family((ref, String skillId) async {
  return ref.watch(ratingRepositoryProvider).getRatingsForSkill(skillId);
});
