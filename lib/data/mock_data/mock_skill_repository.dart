import 'dart:async';
import '../models/skill.dart';
import '../models/app_user.dart';
import '../repositories/skill_repository.dart';
import '../repositories/user_repository.dart';
import '../mock_data/mock_data.dart';

/// In-memory mock implementation of [SkillRepository].
class MockSkillRepository implements SkillRepository {
  MockSkillRepository(this._userRepo);

  static List<Skill> get skills => MockData.skills;

  final UserRepository _userRepo;
  final List<Skill> _skills = List.from(MockData.skills);
  final _streamController = StreamController<List<Skill>>.broadcast();

  @override
  Future<List<Skill>> getSkills({SkillFilter? filter}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _applyFilter(_skills, filter);
  }

  @override
  Future<Skill?> getSkillById(String skillId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _skills.where((s) => s.id == skillId).firstOrNull;
  }

  @override
  Future<List<Skill>> getSkillsByOwner(String ownerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _skills.where((s) => s.ownerId == ownerId).toList();
  }

  @override
  Future<Skill> saveSkill(Skill skill) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _skills.indexWhere((s) => s.id == skill.id);
    if (idx == -1) {
      _skills.add(skill);
    } else {
      _skills[idx] = skill;
    }
    _streamController.add(List.from(_skills));
    return skill;
  }

  @override
  Future<void> deleteSkill(String skillId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _skills.removeWhere((s) => s.id == skillId);
    _streamController.add(List.from(_skills));
  }

  @override
  Future<List<Skill>> getPopularSkills({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List<Skill>.from(_skills)
      ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    return sorted.take(limit).toList();
  }

  @override
  Future<AppUser?> getSkillOwner(String ownerId) async {
    return _userRepo.getUserById(ownerId);
  }

  @override
  Stream<List<Skill>> watchSkills({SkillFilter? filter}) {
    // Emit immediately
    Future.microtask(() {
      _streamController.add(_applyFilter(_skills, filter));
    });
    return _streamController.stream.map((list) => _applyFilter(list, filter));
  }

  List<Skill> _applyFilter(List<Skill> skills, SkillFilter? filter) {
    if (filter == null) return List.from(skills);

    var result = skills.where((s) {
      // Text search
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        final matchTitle = s.title.toLowerCase().contains(q);
        final matchDesc = s.description.toLowerCase().contains(q);
        final matchTags = s.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchDesc && !matchTags) return false;
      }
      // Category
      if (filter.category != null && s.category != filter.category) {
        return false;
      }
      // Level
      if (filter.level != null && s.level != filter.level) return false;
      // Availability
      if (filter.availability != null &&
          s.availability != filter.availability) {
        return false;
      }
      // Min rating
      if (s.avgRating < filter.minRating) return false;
      return true;
    }).toList();

    // Sort
    switch (filter.sortBy) {
      case SkillSortBy.popular:
        result.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
      case SkillSortBy.rating:
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      case SkillSortBy.newest:
        // Mock newest = last in list
        result = result.reversed.toList();
      case SkillSortBy.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }

    return result;
  }

  void dispose() {
    _streamController.close();
  }
}
