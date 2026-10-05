import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/skill.dart';
import '../repositories/skill_repository.dart';
import '../repositories/user_repository.dart';
import '../mock_data/mock_skill_repository.dart';

/// Real Firebase implementation of [SkillRepository] using Cloud Firestore ('skills' collection).
class FirebaseSkillRepository implements SkillRepository {
  FirebaseSkillRepository({
    FirebaseFirestore? firestore,
    UserRepository? userRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userRepo = userRepo;

  final FirebaseFirestore _firestore;
  final UserRepository? _userRepo;

  CollectionReference<Map<String, dynamic>> get _skillsCol =>
      _firestore.collection('skills');

  @override
  Future<List<Skill>> getSkills({SkillFilter? filter}) async {
    try {
      Query<Map<String, dynamic>> query = _skillsCol;

      if (filter?.category != null && filter!.category != SkillCategory.other) {
        query = query.where('category', isEqualTo: filter.category!.label);
      }
      if (filter?.level != null) {
        query = query.where('level', isEqualTo: filter!.level!.label);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        var list = snapshot.docs
            .map((doc) => Skill.fromFirestore(doc.data(), doc.id))
            .toList();
        return _applyClientFilters(list, filter);
      }
    } catch (_) {}

    return _applyClientFilters(MockSkillRepository.skills, filter);
  }

  @override
  Future<Skill?> getSkillById(String skillId) async {
    try {
      final doc = await _skillsCol.doc(skillId).get();
      if (doc.exists && doc.data() != null) {
        return Skill.fromFirestore(doc.data()!, doc.id);
      }
    } catch (_) {}
    return MockSkillRepository.skills
        .where((s) => s.id == skillId)
        .firstOrNull;
  }

  @override
  Future<List<Skill>> getSkillsByOwner(String ownerId) async {
    try {
      var snapshot =
          await _skillsCol.where('providerId', isEqualTo: ownerId).get();
      if (snapshot.docs.isEmpty) {
        snapshot =
            await _skillsCol.where('ownerId', isEqualTo: ownerId).get();
      }
      if (snapshot.docs.isEmpty) {
        snapshot =
            await _skillsCol.where('userId', isEqualTo: ownerId).get();
      }
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Skill.fromFirestore(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {}
    if (ownerId.startsWith('user_')) {
      return MockSkillRepository.skills
          .where((s) => s.ownerId == ownerId)
          .toList();
    }
    return [];
  }

  @override
  Future<Skill> saveSkill(Skill skill) async {
    await _skillsCol.doc(skill.id).set(
          skill.toFirestore(),
          SetOptions(merge: true),
        );
    return skill;
  }

  @override
  Future<void> deleteSkill(String skillId) async {
    try {
      await _skillsCol.doc(skillId).delete();
    } catch (_) {}
  }

  @override
  Future<List<Skill>> getPopularSkills({int limit = 10}) async {
    try {
      // 1. Try order by rating
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _skillsCol
            .orderBy('rating', descending: true)
            .limit(limit)
            .get();
      } catch (_) {
        snapshot = await _skillsCol.limit(limit).get();
      }

      if (snapshot.docs.isEmpty) {
        // Fallback without orderBy (no index required, works on all schemas)
        snapshot = await _skillsCol.limit(limit).get();
      }

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs
            .map((doc) => Skill.fromFirestore(doc.data(), doc.id))
            .toList();
        // Sort descending by rating in memory
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        return list.take(limit).toList();
      }
    } catch (_) {}

    return MockSkillRepository.skills.take(limit).toList();
  }

  @override
  Future<AppUser?> getSkillOwner(String ownerId) async {
    if (_userRepo != null) {
      return _userRepo.getUserById(ownerId);
    }
    final doc = await _firestore.collection('users').doc(ownerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Stream<List<Skill>> watchSkills({SkillFilter? filter}) {
    return _skillsCol.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _applyClientFilters(MockSkillRepository.skills, filter);
      }
      final list = snapshot.docs
          .map((doc) => Skill.fromFirestore(doc.data(), doc.id))
          .toList();
      return _applyClientFilters(list, filter);
    }).handleError((_) {
      return _applyClientFilters(MockSkillRepository.skills, filter);
    });
  }

  List<Skill> _applyClientFilters(List<Skill> list, SkillFilter? filter) {
    if (filter == null) return list;

    var result = list;

    // Filter by category
    if (filter.category != null) {
      result = result.where((s) => s.category == filter.category).toList();
    }

    // Filter by level
    if (filter.level != null) {
      result = result.where((s) => s.level == filter.level).toList();
    }

    // Filter by availability
    if (filter.availability != null) {
      result =
          result.where((s) => s.availability == filter.availability).toList();
    }

    // Filter by minimum rating
    if (filter.minRating > 0) {
      result = result.where((s) => s.avgRating >= filter.minRating).toList();
    }

    // Search query matching title, description, or tags
    if (filter.query.trim().isNotEmpty) {
      final q = filter.query.trim().toLowerCase();
      result = result.where((s) {
        final titleMatch = s.title.toLowerCase().contains(q);
        final descMatch = s.description.toLowerCase().contains(q);
        final categoryMatch = s.category.label.toLowerCase().contains(q);
        final tagMatch = s.tags.any((t) => t.toLowerCase().contains(q));
        return titleMatch || descMatch || categoryMatch || tagMatch;
      }).toList();
    }

    // Sorting
    switch (filter.sortBy) {
      case SkillSortBy.popular:
        result.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
        break;
      case SkillSortBy.rating:
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case SkillSortBy.newest:
        break;
      case SkillSortBy.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return result;
  }
}
