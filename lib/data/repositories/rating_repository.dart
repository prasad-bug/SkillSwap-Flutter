import '../models/rating.dart';

/// Abstract interface for rating operations.
abstract class RatingRepository {
  /// Submit a rating for a completed booking.
  Future<Rating> submitRating(Rating rating);

  /// Get ratings for a user (received).
  Future<List<Rating>> getRatingsForUser(String userId);

  /// Check if a booking has been rated by a user.
  Future<bool> hasRated(String bookingId, String fromUserId);

  /// Get all ratings for a skill.
  Future<List<Rating>> getRatingsForSkill(String skillId);
}
