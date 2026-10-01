import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/booking.dart';

final userBookingsStreamProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  return bookingRepo.watchBookingsForUser(user.id);
});

final skillAvailabilityProvider = FutureProvider.family.autoDispose<List<AvailabilitySlot>, ({String skillId, DateTime month})>((ref, arg) {
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  return bookingRepo.getAvailabilitySlots(arg.skillId, arg.month);
});
