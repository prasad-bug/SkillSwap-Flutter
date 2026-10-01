import 'dart:async';
import '../models/booking.dart';
import '../models/skill.dart';
import '../repositories/booking_repository.dart';
import '../mock_data/mock_data.dart';
import 'package:uuid/uuid.dart';

/// In-memory mock implementation of [BookingRepository].
class MockBookingRepository implements BookingRepository {
  MockBookingRepository() {
    _bookings = List.from(MockData.bookings);
    _streamController = StreamController<List<Booking>>.broadcast();
  }

  late List<Booking> _bookings;
  late StreamController<List<Booking>> _streamController;
  final _uuid = const Uuid();

  @override
  Future<List<Booking>> getBookingsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings
        .where((b) => b.teacherId == userId || b.learnerId == userId)
        .toList();
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookings.where((b) => b.id == bookingId).firstOrNull;
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newBooking = booking.id.isEmpty
        ? booking.copyWith(id: _uuid.v4())
        : booking;
    _bookings.add(newBooking);
    _streamController.add(List.from(_bookings));
    return newBooking;
  }

  @override
  Future<Booking> cancelBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) throw Exception('Booking not found');
    final cancelled =
        _bookings[idx].copyWith(status: BookingStatus.cancelled);
    _bookings[idx] = cancelled;
    _streamController.add(List.from(_bookings));
    return cancelled;
  }

  @override
  Future<Booking> completeBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) throw Exception('Booking not found');
    final completed =
        _bookings[idx].copyWith(status: BookingStatus.completed);
    _bookings[idx] = completed;
    _streamController.add(List.from(_bookings));
    return completed;
  }

  @override
  Future<List<AvailabilitySlot>> getAvailabilitySlots(
      String skillId, DateTime month) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final skill = MockData.getSkillById(skillId);
    if (skill == null || skill.availability == AvailabilityStatus.unavailable) {
      return [];
    }

    final slots = <AvailabilitySlot>[];
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        continue;
      }
      // Skip Sundays for some variety
      if (date.weekday == DateTime.sunday) continue;

      // Generate time slots: 9am, 11am, 2pm, 4pm
      final timeSlots = [9, 11, 14, 16];
      for (final hour in timeSlots) {
        // Limited availability: only some slots
        if (skill.availability == AvailabilityStatus.limited &&
            (hour == 9 || hour == 16)) {
          continue;
        }
        final start = DateTime(date.year, date.month, date.day, hour);
        final end = start.add(Duration(minutes: skill.sessionDurationMins));
        final isBooked = _bookings.any((b) =>
            b.skillId == skillId &&
            b.status != BookingStatus.cancelled &&
            b.dateTime.year == date.year &&
            b.dateTime.month == date.month &&
            b.dateTime.day == date.day &&
            b.dateTime.hour == hour);

        slots.add(AvailabilitySlot(
          date: date,
          startTime: start,
          endTime: end,
          isBooked: isBooked,
        ));
      }
    }
    return slots;
  }

  @override
  Stream<List<Booking>> watchBookingsForUser(String userId) {
    Future.microtask(() {
      _streamController.add(
        _bookings
            .where((b) => b.teacherId == userId || b.learnerId == userId)
            .toList(),
      );
    });
    return _streamController.stream.map(
      (bookings) => bookings
          .where((b) => b.teacherId == userId || b.learnerId == userId)
          .toList(),
    );
  }

  @override
  Future<bool> isSlotBooked(
      String skillId, DateTime dateTime, int durationMins) async {
    final endTime = dateTime.add(Duration(minutes: durationMins));
    return _bookings.any((b) =>
        b.skillId == skillId &&
        b.status != BookingStatus.cancelled &&
        b.dateTime.isBefore(endTime) &&
        b.dateTime.add(Duration(minutes: b.durationMins)).isAfter(dateTime));
  }

  @override
  Future<List<Booking>> getUpcomingBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return _bookings
        .where((b) =>
            (b.teacherId == userId || b.learnerId == userId) &&
            (b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.pending) &&
            b.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void dispose() {
    _streamController.close();
  }
}
