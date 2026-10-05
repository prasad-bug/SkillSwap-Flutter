import 'package:equatable/equatable.dart';

/// Skill category enumeration.
enum SkillCategory {
  technology,
  music,
  language,
  art,
  fitness,
  cooking,
  business,
  other;

  String get label {
    switch (this) {
      case SkillCategory.technology:
        return 'Technology';
      case SkillCategory.music:
        return 'Music';
      case SkillCategory.language:
        return 'Language';
      case SkillCategory.art:
        return 'Art';
      case SkillCategory.fitness:
        return 'Fitness';
      case SkillCategory.cooking:
        return 'Cooking';
      case SkillCategory.business:
        return 'Business';
      case SkillCategory.other:
        return 'Other';
    }
  }

  static SkillCategory fromString(String value) {
    return SkillCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkillCategory.other,
    );
  }
}

/// Skill proficiency level.
enum SkillLevel {
  beginner,
  intermediate,
  expert;

  String get label {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.expert:
        return 'Expert';
    }
  }

  static SkillLevel fromString(String value) {
    return SkillLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkillLevel.beginner,
    );
  }
}

/// Availability status for a skill.
enum AvailabilityStatus {
  available,
  limited,
  unavailable;

  String get label {
    switch (this) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.limited:
        return 'Limited';
      case AvailabilityStatus.unavailable:
        return 'Unavailable';
    }
  }

  static AvailabilityStatus fromString(String value) {
    return AvailabilityStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AvailabilityStatus.unavailable,
    );
  }
}

/// A skill offered by a user.
class Skill extends Equatable {
  const Skill({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.availability,
    this.tags = const [],
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.sessionDurationMins = 60,
    this.imageUrl,
    this.curriculum = const [],
    this.prerequisites = const [],
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final SkillCategory category;
  final SkillLevel level;
  final AvailabilityStatus availability;
  final List<String> tags;
  final double avgRating;
  final int ratingCount;
  final int sessionDurationMins;
  final String? imageUrl;
  final List<String> curriculum;
  final List<String> prerequisites;

  Skill copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    SkillCategory? category,
    SkillLevel? level,
    AvailabilityStatus? availability,
    List<String>? tags,
    double? avgRating,
    int? ratingCount,
    int? sessionDurationMins,
    String? imageUrl,
    List<String>? curriculum,
    List<String>? prerequisites,
  }) {
    return Skill(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      availability: availability ?? this.availability,
      tags: tags ?? this.tags,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
      sessionDurationMins: sessionDurationMins ?? this.sessionDurationMins,
      imageUrl: imageUrl ?? this.imageUrl,
      curriculum: curriculum ?? this.curriculum,
      prerequisites: prerequisites ?? this.prerequisites,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'category': category.name,
      'level': level.name,
      'availability': availability.name,
      'tags': tags,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
      'sessionDurationMins': sessionDurationMins,
      'imageUrl': imageUrl,
      'curriculum': curriculum,
      'prerequisites': prerequisites,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.label,
      'level': level.label,
      'providerId': ownerId,
      'ownerId': ownerId,
      'userId': ownerId,
      'providerName': '',
      'providerImage': imageUrl ?? '',
      'rating': avgRating,
      'totalRatings': ratingCount,
      'availability': availability.label,
      'sessionDurationMins': sessionDurationMins,
      'tags': tags,
      'curriculum': curriculum,
      'prerequisites': prerequisites,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    AvailabilityStatus avail = AvailabilityStatus.available;
    final rawAvail = map['availability'];
    if (rawAvail is String) {
      avail = AvailabilityStatus.fromString(rawAvail);
    } else if (rawAvail is List && rawAvail.isNotEmpty) {
      avail = AvailabilityStatus.fromString(rawAvail.first.toString());
    }

    return Skill(
      id: (map['id'] ?? '') as String,
      ownerId: (map['ownerId'] ?? map['providerId'] ?? map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: SkillCategory.fromString((map['category'] ?? 'other') as String),
      level: SkillLevel.fromString((map['level'] ?? map['experienceLevel'] ?? 'beginner') as String),
      availability: avail,
      tags: List<String>.from(map['tags'] ?? []),
      avgRating: (map['avgRating'] ?? map['rating'] ?? map['userRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] ?? map['totalRatings'] as num?)?.toInt() ?? 0,
      sessionDurationMins: (map['sessionDurationMins'] as int?) ?? 60,
      imageUrl: map['imageUrl'] as String? ?? map['providerImage'] as String? ?? map['userAvatarUrl'] as String?,
      curriculum: List<String>.from(map['curriculum'] ?? []),
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
    );
  }

  factory Skill.fromFirestore(Map<String, dynamic> data, String docId) {
    return Skill.fromMap({
      'id': docId,
      ...data,
    });
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        title,
        description,
        category,
        level,
        availability,
        tags,
        avgRating,
        ratingCount,
        sessionDurationMins,
        imageUrl,
        curriculum,
        prerequisites,
      ];
}
