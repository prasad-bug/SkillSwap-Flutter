import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/skill.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/app_user.dart';

/// Provider for popular skills on dashboard.
final popularSkillsProvider = FutureProvider<List<Skill>>((ref) async {
  final repo = ref.watch(skillRepositoryProvider);
  return repo.getPopularSkills(limit: 6);
});

/// Provider for upcoming bookings on dashboard.
final upcomingBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = await ref.watch(userRepositoryProvider).getCurrentUser();
  if (user == null) return [];
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getUpcomingBookings(user.id);
});

/// Provider for chat threads on dashboard.
final dashboardChatsProvider = StreamProvider<List<ChatThread>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.asData?.value?.id ?? '';
  if (userId.isEmpty) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchThreadsForUser(userId);
});

/// Provider to load a user by ID (for displaying thread partner names).
final userByIdProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  return ref.watch(userRepositoryProvider).getUserById(userId);
});
