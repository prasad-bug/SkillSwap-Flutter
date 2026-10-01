import '../models/rating.dart';
import '../repositories/rating_repository.dart';
import '../mock_data/mock_data.dart';
import 'package:uuid/uuid.dart';

/// In-memory mock implementation of [RatingRepository].
class MockRatingRepository implements RatingRepository {
  MockRatingRepository() {
    _ratings = List.from(MockData.ratings);
  }

  late List<Rating> _ratings;
  final _uuid = const Uuid();

  @override
  Future<Rating> submitRating(Rating rating) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final already = _ratings.any((r) =>
        r.bookingId == rating.bookingId && r.fromUserId == rating.fromUserId);
    if (already) throw Exception('Already rated this booking.');

    final newRating = rating.id.isEmpty
        ? rating.copyWith(id: _uuid.v4())
        : rating;
    _ratings.add(newRating);
    return newRating;
  }

  @override
  Future<List<Rating>> getRatingsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _ratings.where((r) => r.toUserId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<bool> hasRated(String bookingId, String fromUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _ratings.any(
        (r) => r.bookingId == bookingId && r.fromUserId == fromUserId);
  }

  @override
  Future<List<Rating>> getRatingsForSkill(String skillId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _ratings.where((r) => r.skillId == skillId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
