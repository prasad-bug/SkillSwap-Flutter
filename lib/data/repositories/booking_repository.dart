import '../models/booking.dart';

/// Abstract interface for booking operations.
abstract class BookingRepository {
  /// Get bookings for a user (as learner or teacher).
  Future<List<Booking>> getBookingsForUser(String userId);

  /// Get a booking by id.
  Future<Booking?> getBookingById(String bookingId);

  /// Create a new booking.
  Future<Booking> createBooking(Booking booking);

  /// Cancel a booking.
  Future<Booking> cancelBooking(String bookingId);

  /// Complete a booking (mark as completed).
  Future<Booking> completeBooking(String bookingId);

  /// Get availability slots for a skill.
  Future<List<AvailabilitySlot>> getAvailabilitySlots(
      String skillId, DateTime month);

  /// Stream bookings for a user.
  Stream<List<Booking>> watchBookingsForUser(String userId);

  /// Check if a slot is already booked.
  Future<bool> isSlotBooked(String skillId, DateTime dateTime, int durationMins);

  /// Get upcoming bookings (confirmed, in the future).
  Future<List<Booking>> getUpcomingBookings(String userId);
}

/// Centralised booking validation.
class BookingValidator {
  static String? validateBookingRequest({
    required String currentUserId,
    required String teacherId,
    required DateTime dateTime,
    required int durationMins,
    required List<Booking> existingBookings,
  }) {
    // Cannot book your own skill
    if (currentUserId == teacherId) {
      return 'You cannot book your own skill.';
    }

    // Cannot book in the past
    if (dateTime.isBefore(DateTime.now())) {
      return 'Cannot book a session in the past.';
    }

    // Cannot book less than 30 minutes from now
    if (dateTime.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      return 'Please book at least 30 minutes in advance.';
    }

    // Duration must be valid
    if (durationMins < 30 || durationMins > 240) {
      return 'Session duration must be between 30 and 240 minutes.';
    }

    // Check for overlapping sessions for the learner
    final proposedEnd = dateTime.add(Duration(minutes: durationMins));
    for (final booking in existingBookings) {
      if (booking.status == BookingStatus.cancelled) continue;
      if (booking.learnerId != currentUserId) continue;

      final existingEnd =
          booking.dateTime.add(Duration(minutes: booking.durationMins));
      final overlaps = dateTime.isBefore(existingEnd) &&
          proposedEnd.isAfter(booking.dateTime);
      if (overlaps) {
        return 'You already have a session scheduled at that time.';
      }
    }

    return null; // valid
  }
}
