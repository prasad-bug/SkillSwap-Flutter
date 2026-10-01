import 'package:equatable/equatable.dart';

/// Status of a booking session.
enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BookingStatus fromString(String v) => BookingStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => BookingStatus.pending,
      );
}

/// A session booking.
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.skillId,
    required this.teacherId,
    required this.learnerId,
    required this.dateTime,
    required this.durationMins,
    this.status = BookingStatus.pending,
    this.notes = '',
    this.skillTitle = '',
  });

  final String id;
  final String skillId;
  final String teacherId;
  final String learnerId;
  final DateTime dateTime;
  final int durationMins;
  final BookingStatus status;
  final String notes;
  final String skillTitle;

  Booking copyWith({
    String? id,
    String? skillId,
    String? teacherId,
    String? learnerId,
    DateTime? dateTime,
    int? durationMins,
    BookingStatus? status,
    String? notes,
    String? skillTitle,
  }) {
    return Booking(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      teacherId: teacherId ?? this.teacherId,
      learnerId: learnerId ?? this.learnerId,
      dateTime: dateTime ?? this.dateTime,
      durationMins: durationMins ?? this.durationMins,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      skillTitle: skillTitle ?? this.skillTitle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skillId': skillId,
      'teacherId': teacherId,
      'learnerId': learnerId,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'durationMins': durationMins,
      'status': status.name,
      'notes': notes,
      'skillTitle': skillTitle,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      skillId: map['skillId'] as String,
      teacherId: map['teacherId'] as String,
      learnerId: map['learnerId'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int),
      durationMins: (map['durationMins'] as int?) ?? 60,
      status: BookingStatus.fromString((map['status'] as String?) ?? 'pending'),
      notes: (map['notes'] as String?) ?? '',
      skillTitle: (map['skillTitle'] as String?) ?? '',
    );
  }

  DateTime get endTime =>
      dateTime.add(Duration(minutes: durationMins));

  bool overlapsWith(Booking other) {
    return dateTime.isBefore(other.endTime) &&
        endTime.isAfter(other.dateTime);
  }

  @override
  List<Object?> get props => [
        id,
        skillId,
        teacherId,
        learnerId,
        dateTime,
        durationMins,
        status,
        notes,
        skillTitle,
      ];
}

/// An availability slot for a skill/user.
class AvailabilitySlot extends Equatable {
  const AvailabilitySlot({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
  });

  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;

  AvailabilitySlot copyWith({
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    bool? isBooked,
  }) {
    return AvailabilitySlot(
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBooked: isBooked ?? this.isBooked,
    );
  }

  @override
  List<Object?> get props => [date, startTime, endTime, isBooked];
}
