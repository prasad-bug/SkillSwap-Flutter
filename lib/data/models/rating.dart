import 'package:equatable/equatable.dart';

/// A user rating for a completed booking.
class Rating extends Equatable {
  const Rating({
    required this.id,
    required this.bookingId,
    required this.fromUserId,
    required this.toUserId,
    required this.stars,
    required this.review,
    required this.createdAt,
    this.skillId = '',
    this.skillTitle = '',
    this.fromUserName = '',
    this.fromUserAvatarUrl,
  });

  final String id;
  final String bookingId;
  final String fromUserId;
  final String toUserId;
  final int stars; // 1-5
  final String review;
  final DateTime createdAt;
  final String skillId;
  final String skillTitle;
  final String fromUserName;
  final String? fromUserAvatarUrl;

  Rating copyWith({
    String? id,
    String? bookingId,
    String? fromUserId,
    String? toUserId,
    int? stars,
    String? review,
    DateTime? createdAt,
    String? skillId,
    String? skillTitle,
    String? fromUserName,
    String? fromUserAvatarUrl,
  }) {
    return Rating(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      stars: stars ?? this.stars,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      skillId: skillId ?? this.skillId,
      skillTitle: skillTitle ?? this.skillTitle,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatarUrl: fromUserAvatarUrl ?? this.fromUserAvatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'stars': stars,
      'review': review,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'skillId': skillId,
      'skillTitle': skillTitle,
      'fromUserName': fromUserName,
      'fromUserAvatarUrl': fromUserAvatarUrl,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      id: map['id'] as String,
      bookingId: map['bookingId'] as String,
      fromUserId: map['fromUserId'] as String,
      toUserId: map['toUserId'] as String,
      stars: (map['stars'] as int?) ?? 0,
      review: (map['review'] as String?) ?? '',
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      skillId: (map['skillId'] as String?) ?? '',
      skillTitle: (map['skillTitle'] as String?) ?? '',
      fromUserName: (map['fromUserName'] as String?) ?? '',
      fromUserAvatarUrl: map['fromUserAvatarUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        fromUserId,
        toUserId,
        stars,
        review,
        createdAt,
        skillId,
        skillTitle,
        fromUserName,
        fromUserAvatarUrl,
      ];
}
