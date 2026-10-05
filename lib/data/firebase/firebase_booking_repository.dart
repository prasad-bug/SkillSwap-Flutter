import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../repositories/booking_repository.dart';

/// Real Firebase implementation of [BookingRepository] using Cloud Firestore ('bookings' collection).
class FirebaseBookingRepository implements BookingRepository {
  FirebaseBookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _firestore.collection('bookings');

  @override
  Future<List<Booking>> getBookingsForUser(String userId) async {
    // Check both student and provider roles
    final learnerSnap =
        await _bookingsCol.where('studentId', isEqualTo: userId).get();
    final teacherSnap =
        await _bookingsCol.where('providerId', isEqualTo: userId).get();

    final map = <String, Booking>{};
    for (final doc in learnerSnap.docs) {
      map[doc.id] = Booking.fromFirestore(doc.data(), doc.id);
    }
    for (final doc in teacherSnap.docs) {
      map[doc.id] = Booking.fromFirestore(doc.data(), doc.id);
    }

    final list = map.values.toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await _bookingsCol.doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Booking.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    // 1. Verify availability and prevent overlapping booking for same provider
    final conflict = await isSlotBooked(
      booking.skillId,
      booking.dateTime,
      booking.durationMins,
    );
    if (conflict) {
      throw Exception(
        'This time slot is already booked. Please choose another available slot.',
      );
    }

    // 2. Persist booking
    final docRef = booking.id.isNotEmpty
        ? _bookingsCol.doc(booking.id)
        : _bookingsCol.doc();

    final toSave = booking.copyWith(id: docRef.id);
    await docRef.set(toSave.toFirestore());
    return toSave;
  }

  @override
  Future<Booking> cancelBooking(String bookingId) async {
    await _bookingsCol.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final updated = await getBookingById(bookingId);
    if (updated == null) throw Exception('Booking not found');
    return updated;
  }

  @override
  Future<Booking> completeBooking(String bookingId) async {
    await _bookingsCol.doc(bookingId).update({
      'status': BookingStatus.completed.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final updated = await getBookingById(bookingId);
    if (updated == null) throw Exception('Booking not found');
    return updated;
  }

  @override
  Future<bool> isSlotBooked(
    String skillId,
    DateTime dateTime,
    int durationMins,
  ) async {
    final proposedEnd = dateTime.add(Duration(minutes: durationMins));

    // Retrieve active bookings for this skill
    final snapshot = await _bookingsCol
        .where('skillId', isEqualTo: skillId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .get();

    for (final doc in snapshot.docs) {
      final existing = Booking.fromFirestore(doc.data(), doc.id);
      final existingEnd = existing.dateTime.add(Duration(minutes: existing.durationMins));
      if (dateTime.isBefore(existingEnd) && proposedEnd.isAfter(existing.dateTime)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<AvailabilitySlot>> getAvailabilitySlots(
    String skillId,
    DateTime month,
  ) async {
    final slots = <AvailabilitySlot>[];
    final times = [
      '09:00',
      '10:00',
      '11:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
    ];

    // Generate slots for each day in month
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      if (date.weekday == DateTime.sunday) continue;

      for (final t in times) {
        final parts = t.split(':').map(int.parse).toList();
        final slotStart = DateTime(date.year, date.month, date.day, parts[0], parts[1]);
        final slotEnd = slotStart.add(const Duration(hours: 1));

        final booked = await isSlotBooked(skillId, slotStart, 60);
        slots.add(AvailabilitySlot(
          date: date,
          startTime: slotStart,
          endTime: slotEnd,
          isBooked: booked,
        ));
      }
    }
    return slots;
  }

  @override
  Stream<List<Booking>> watchBookingsForUser(String userId) {
    return _bookingsCol.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc.data(), doc.id))
          .where((b) => b.learnerId == userId || b.teacherId == userId)
          .toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  @override
  Future<List<Booking>> getUpcomingBookings(String userId) async {
    final all = await getBookingsForUser(userId);
    final now = DateTime.now();
    return all.where((b) {
      return (b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.pending) &&
          b.dateTime.isAfter(now);
    }).toList();
  }
}
