import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/skill.dart';
import '../models/booking.dart';

/// Service to seed initial realistic demo data to Cloud Firestore.
/// Matches the required SkillSwap demonstration records:
/// - Users: Rahul Sharma, Aman Patel, Priya Shah, Maya Lin, Alex Rivera
/// - Skills: Flutter Development, Java Programming, UI/UX Design, Python, Guitar, Digital Marketing, etc.
class FirestoreSeedService {
  FirestoreSeedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Checks if skills collection is empty. If so, populates initial demo data.
  Future<void> seedIfEmpty() async {
    try {
      final snapshot = await _firestore.collection('skills').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Already seeded
      }
      await seedAll();
    } catch (_) {
      // Ignored if offline or rules not configured yet
    }
  }

  Future<void> seedAll() async {
    final batch = _firestore.batch();

    // 1. Seed Users
    final users = [
      const AppUser(
        id: 'user_rahul',
        name: 'Rahul Sharma',
        email: 'rahul.sharma@example.com',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        bio: 'Senior Flutter developer & mentor with 6+ years building mobile apps.',
        location: 'Bengaluru, India',
        offeredSkillIds: ['skill_flutter', 'skill_dart'],
        wantedSkills: ['UI/UX Design', 'Guitar'],
        avgRating: 4.9,
        ratingCount: 32,
      ),
      const AppUser(
        id: 'user_aman',
        name: 'Aman Patel',
        email: 'aman.patel@example.com',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        bio: 'Backend systems engineer specializing in Java, Spring Boot & Python.',
        location: 'Mumbai, India',
        offeredSkillIds: ['skill_java', 'skill_python'],
        wantedSkills: ['Flutter Development', 'Digital Marketing'],
        avgRating: 4.8,
        ratingCount: 19,
      ),
      const AppUser(
        id: 'user_priya',
        name: 'Priya Shah',
        email: 'priya.shah@example.com',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        bio: 'Product Designer at FinTech. Passionate about design systems & Figma tokens.',
        location: 'New Delhi, India',
        offeredSkillIds: ['skill_uiux', 'skill_figma'],
        wantedSkills: ['Python', 'Conversational French'],
        avgRating: 4.9,
        ratingCount: 28,
      ),
      const AppUser(
        id: 'user_maya',
        name: 'Maya Lin',
        email: 'maya.lin@example.com',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        bio: 'Design systems lead at StudioCraft. Figma auto-layout enthusiast.',
        location: 'San Francisco, CA',
        offeredSkillIds: ['skill_figma_systems'],
        wantedSkills: ['Conversational French'],
        avgRating: 5.0,
        ratingCount: 42,
      ),
      const AppUser(
        id: 'current_user',
        name: 'Alex Rivera',
        email: 'alex.rivera@example.com',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        bio: 'Self-taught mobile explorer & native French speaker trading languages for design mastery.',
        location: 'Austin, TX',
        offeredSkillIds: ['skill_french'],
        wantedSkills: ['Figma Design Systems', 'Flutter Development'],
        avgRating: 4.9,
        ratingCount: 18,
      ),
    ];

    for (final u in users) {
      final docRef = _firestore.collection('users').doc(u.id);
      batch.set(docRef, u.toFirestore());
    }

    // 2. Seed Skills
    final skills = [
      const Skill(
        id: 'skill_flutter',
        ownerId: 'user_rahul',
        title: 'Flutter Development',
        description: 'Learn modern Flutter architecture, Riverpod state management, and production-ready clean code.',
        category: SkillCategory.technology,
        level: SkillLevel.intermediate,
        availability: AvailabilityStatus.available,
        avgRating: 4.9,
        ratingCount: 32,
        tags: ['Flutter', 'Dart', 'Riverpod', 'Mobile'],
        sessionDurationMins: 60,
      ),
      const Skill(
        id: 'skill_java',
        ownerId: 'user_aman',
        title: 'Java Programming',
        description: 'Comprehensive core Java, OOP paradigms, multithreading, and Spring Boot microservices.',
        category: SkillCategory.technology,
        level: SkillLevel.intermediate,
        availability: AvailabilityStatus.available,
        avgRating: 4.8,
        ratingCount: 19,
        tags: ['Java', 'Spring Boot', 'Backend'],
        sessionDurationMins: 60,
      ),
      const Skill(
        id: 'skill_uiux',
        ownerId: 'user_priya',
        title: 'UI/UX Design',
        description: 'User-centered design principles, wireframing, interactive prototyping, and usability research.',
        category: SkillCategory.art,
        level: SkillLevel.beginner,
        availability: AvailabilityStatus.available,
        avgRating: 4.9,
        ratingCount: 28,
        tags: ['UI/UX', 'Figma', 'Prototyping', 'Design'],
        sessionDurationMins: 60,
      ),
      const Skill(
        id: 'skill_python',
        ownerId: 'user_aman',
        title: 'Python for Data & Automation',
        description: 'Python essentials from data structures to web scraping, automation scripts, and REST APIs.',
        category: SkillCategory.technology,
        level: SkillLevel.beginner,
        availability: AvailabilityStatus.available,
        avgRating: 4.7,
        ratingCount: 14,
        tags: ['Python', 'Automation', 'Scripting'],
        sessionDurationMins: 45,
      ),
      const Skill(
        id: 'skill_guitar',
        ownerId: 'user_rahul',
        title: 'Acoustic Guitar Basics',
        description: 'Fingerstyle fundamentals, open chords, rhythm strumming, and playing your favorite melodies.',
        category: SkillCategory.music,
        level: SkillLevel.beginner,
        availability: AvailabilityStatus.limited,
        avgRating: 5.0,
        ratingCount: 12,
        tags: ['Guitar', 'Music', 'Chords'],
        sessionDurationMins: 45,
      ),
      const Skill(
        id: 'skill_marketing',
        ownerId: 'user_priya',
        title: 'Digital Marketing & Growth',
        description: 'Organic SEO, content funnel strategy, social media growth, and conversion optimization.',
        category: SkillCategory.business,
        level: SkillLevel.intermediate,
        availability: AvailabilityStatus.available,
        avgRating: 4.6,
        ratingCount: 16,
        tags: ['Marketing', 'SEO', 'Growth', 'Content'],
        sessionDurationMins: 60,
      ),
      const Skill(
        id: 'skill_figma_systems',
        ownerId: 'user_maya',
        title: 'Figma Design Systems',
        description: 'Build enterprise-grade design tokens, component variants, responsive autolayout, and theme guides.',
        category: SkillCategory.art,
        level: SkillLevel.expert,
        availability: AvailabilityStatus.available,
        avgRating: 5.0,
        ratingCount: 42,
        tags: ['Figma', 'Design Systems', 'Autolayout', 'Tokens'],
        sessionDurationMins: 45,
      ),
      const Skill(
        id: 'skill_french',
        ownerId: 'current_user',
        title: 'Conversational French',
        description: 'Native French practice focusing on everyday pronunciation, idioms, and casual conversation.',
        category: SkillCategory.language,
        level: SkillLevel.intermediate,
        availability: AvailabilityStatus.available,
        avgRating: 4.9,
        ratingCount: 18,
        tags: ['French', 'Language', 'Pronunciation'],
        sessionDurationMins: 30,
      ),
    ];

    for (final s in skills) {
      final docRef = _firestore.collection('skills').doc(s.id);
      batch.set(docRef, s.toFirestore());
    }

    // 3. Seed Sample Booking
    final sampleBooking = Booking(
      id: 'booking_sample_1',
      skillId: 'skill_figma_systems',
      teacherId: 'user_maya',
      learnerId: 'current_user',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      durationMins: 45,
      status: BookingStatus.confirmed,
      skillTitle: 'Figma Design Systems',
      notes: 'Reviewing design tokens and component responsive autolayout.',
    );
    batch.set(
      _firestore.collection('bookings').doc(sampleBooking.id),
      sampleBooking.toFirestore(),
    );

    // 4. Seed Chat Thread
    final chatDoc = _firestore.collection('chats').doc('thread_1');
    batch.set(chatDoc, {
      'participants': ['current_user', 'user_maya'],
      'participantIds': ['current_user', 'user_maya'],
      'lastMessage': 'See you at our session on Friday!',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'unreadCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final msgDoc = chatDoc.collection('messages').doc('msg_1');
    batch.set(msgDoc, {
      'senderId': 'user_maya',
      'receiverId': 'current_user',
      'message': 'Hi Alex! Looking forward to reviewing design tokens with you.',
      'text': 'Hi Alex! Looking forward to reviewing design tokens with you.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
      'status': 'read',
    });

    // 5. Seed Sample Ratings
    final ratingDoc = _firestore.collection('ratings').doc('rate_sample_1');
    batch.set(ratingDoc, {
      'id': 'rate_sample_1',
      'bookingId': 'booking_completed_prev',
      'userId': 'current_user',
      'fromUserId': 'current_user',
      'providerId': 'user_maya',
      'toUserId': 'user_maya',
      'skillId': 'skill_figma_systems',
      'skillTitle': 'Figma Design Systems',
      'rating': 5,
      'stars': 5,
      'review': "Maya's breakdown of design tokens made everything click instantly. Incredible mentor!",
      'fromUserName': 'Alex Rivera',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
    });

    await batch.commit();
  }
}
