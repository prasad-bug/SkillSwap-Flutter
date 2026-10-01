import 'package:equatable/equatable.dart';

/// Application user model.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio = '',
    this.location = '',
    this.offeredSkillIds = const [],
    this.wantedSkills = const [],
    this.avgRating = 0.0,
    this.ratingCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String bio;
  final String location;
  final List<String> offeredSkillIds;
  final List<String> wantedSkills;
  final double avgRating;
  final int ratingCount;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    String? location,
    List<String>? offeredSkillIds,
    List<String>? wantedSkills,
    double? avgRating,
    int? ratingCount,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      offeredSkillIds: offeredSkillIds ?? this.offeredSkillIds,
      wantedSkills: wantedSkills ?? this.wantedSkills,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'offeredSkillIds': offeredSkillIds,
      'wantedSkills': wantedSkills,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      bio: (map['bio'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      offeredSkillIds: List<String>.from(map['offeredSkillIds'] ?? []),
      wantedSkills: List<String>.from(map['wantedSkills'] ?? []),
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as int?) ?? 0,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatarUrl,
        bio,
        location,
        offeredSkillIds,
        wantedSkills,
        avgRating,
        ratingCount,
      ];
}
