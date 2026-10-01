import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/skill_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/rating_repository.dart';
import '../../data/mock_data/mock_user_repository.dart';
import '../../data/mock_data/mock_skill_repository.dart';
import '../../data/mock_data/mock_chat_repository.dart';
import '../../data/mock_data/mock_booking_repository.dart';
import '../../data/mock_data/mock_rating_repository.dart';
import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Providers
// Switching useMockRepo flag here toggles between Mock and Firebase repos.
// ─────────────────────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (AppConstants.useMockRepo) {
    return MockUserRepository();
  }
  // TODO: return FirebaseUserRepository() when Firebase is configured
  throw UnimplementedError('Firebase repos not yet connected');
});

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  if (AppConstants.useMockRepo) {
    final userRepo = ref.watch(userRepositoryProvider);
    return MockSkillRepository(userRepo);
  }
  throw UnimplementedError('Firebase repos not yet connected');
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConstants.useMockRepo) {
    return MockChatRepository();
  }
  throw UnimplementedError('Firebase repos not yet connected');
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  if (AppConstants.useMockRepo) {
    return MockBookingRepository();
  }
  throw UnimplementedError('Firebase repos not yet connected');
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  if (AppConstants.useMockRepo) {
    return MockRatingRepository();
  }
  throw UnimplementedError('Firebase repos not yet connected');
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth Provider — current user stream
// ─────────────────────────────────────────────────────────────────────────────

final currentUserProvider = StreamProvider((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.currentUserStream;
});
