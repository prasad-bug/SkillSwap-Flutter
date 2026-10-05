import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';
import '../repositories/rating_repository.dart';

/// Real Firebase implementation of [RatingRepository] using Cloud Firestore ('ratings' collection).
/// Updates average rating in both `users` and `skills` collections upon submission.
class FirebaseRatingRepository implements RatingRepository {
  FirebaseRatingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ratingsCol =>
      _firestore.collection('ratings');

  @override
  Future<Rating> submitRating(Rating rating) async {
    // 1. Check for duplicate review on same booking
    final exists = await hasRated(rating.bookingId, rating.fromUserId);
    if (exists) {
      throw Exception('You have already submitted a rating for this session.');
    }

    final docRef = rating.id.isNotEmpty
        ? _ratingsCol.doc(rating.id)
        : _ratingsCol.doc();

    final toSave = rating.copyWith(id: docRef.id);

    // 2. Write rating record
    await docRef.set(toSave.toFirestore());

    // 3. Atomically update Provider/Teacher average rating in `users`
    try {
      final userRef = _firestore.collection('users').doc(rating.toUserId);
      final userDoc = await userRef.get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final currentAvg =
            (data['rating'] ?? data['avgRating'] ?? 0.0 as num).toDouble();
        final currentCount =
            (data['totalRatings'] ?? data['ratingCount'] ?? 0 as num).toInt();

        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + rating.stars) / newCount;

        await userRef.update({
          'rating': double.parse(newAvg.toStringAsFixed(1)),
          'avgRating': double.parse(newAvg.toStringAsFixed(1)),
          'totalRatings': newCount,
          'ratingCount': newCount,
        });
      }
    } catch (_) {}

    // 4. Update Skill average rating in `skills`
    try {
      if (rating.skillId.isNotEmpty) {
        final skillRef = _firestore.collection('skills').doc(rating.skillId);
        final skillDoc = await skillRef.get();
        if (skillDoc.exists && skillDoc.data() != null) {
          final data = skillDoc.data()!;
          final currentAvg =
              (data['rating'] ?? data['avgRating'] ?? 0.0 as num).toDouble();
          final currentCount =
              (data['totalRatings'] ?? data['ratingCount'] ?? 0 as num).toInt();

          final newCount = currentCount + 1;
          final newAvg =
              ((currentAvg * currentCount) + rating.stars) / newCount;

          await skillRef.update({
            'rating': double.parse(newAvg.toStringAsFixed(1)),
            'avgRating': double.parse(newAvg.toStringAsFixed(1)),
            'totalRatings': newCount,
            'ratingCount': newCount,
          });
        }
      }
    } catch (_) {}

    return toSave;
  }

  @override
  Future<List<Rating>> getRatingsForUser(String userId) async {
    final snapshot =
        await _ratingsCol.where('providerId', isEqualTo: userId).get();
    if (snapshot.docs.isEmpty) {
      final fallbackSnapshot =
          await _ratingsCol.where('toUserId', isEqualTo: userId).get();
      final list = fallbackSnapshot.docs
          .map((doc) => Rating.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final list = snapshot.docs
        .map((doc) => Rating.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<bool> hasRated(String bookingId, String fromUserId) async {
    if (bookingId.isEmpty) return false;
    final snap1 = await _ratingsCol
        .where('bookingId', isEqualTo: bookingId)
        .where('userId', isEqualTo: fromUserId)
        .get();
    if (snap1.docs.isNotEmpty) return true;

    final snap2 = await _ratingsCol
        .where('bookingId', isEqualTo: bookingId)
        .where('fromUserId', isEqualTo: fromUserId)
        .get();
    return snap2.docs.isNotEmpty;
  }

  @override
  Future<List<Rating>> getRatingsForSkill(String skillId) async {
    final snapshot =
        await _ratingsCol.where('skillId', isEqualTo: skillId).get();
    final list = snapshot.docs
        .map((doc) => Rating.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
