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
import '../../data/firebase/firebase_user_repository.dart';
import '../../data/firebase/firebase_skill_repository.dart';
import '../../data/firebase/firebase_chat_repository.dart';
import '../../data/firebase/firebase_booking_repository.dart';
import '../../data/firebase/firebase_rating_repository.dart';
import '../../data/firebase/firebase_storage_service.dart';
import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Providers
// Automatically connects to Firebase backend when available, or Mock repo.
// ─────────────────────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (AppConstants.useMockRepo || !AppConstants.isFirebaseAvailable) {
    return MockUserRepository();
  }
  return FirebaseUserRepository();
});

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  if (AppConstants.useMockRepo || !AppConstants.isFirebaseAvailable) {
    final userRepo = ref.watch(userRepositoryProvider);
    return MockSkillRepository(userRepo);
  }
  final userRepo = ref.watch(userRepositoryProvider);
  return FirebaseSkillRepository(userRepo: userRepo);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConstants.useMockRepo || !AppConstants.isFirebaseAvailable) {
    return MockChatRepository();
  }
  return FirebaseChatRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  if (AppConstants.useMockRepo || !AppConstants.isFirebaseAvailable) {
    return MockBookingRepository();
  }
  return FirebaseBookingRepository();
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  if (AppConstants.useMockRepo || !AppConstants.isFirebaseAvailable) {
    return MockRatingRepository();
  }
  return FirebaseRatingRepository();
});

final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth Provider — current user stream
// ─────────────────────────────────────────────────────────────────────────────

final currentUserProvider = StreamProvider((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.currentUserStream;
});
