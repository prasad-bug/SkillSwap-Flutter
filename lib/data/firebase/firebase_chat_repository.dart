import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../repositories/chat_repository.dart';

/// Real Firebase implementation of [ChatRepository] using Cloud Firestore.
/// Matches schema:
/// - chats/{chatId}
/// - chats/{chatId}/messages/{messageId}
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _firestore.collection('chats');

  @override
  Stream<List<ChatThread>> watchThreadsForUser(String userId) {
    return _chatsCol
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final threads = snapshot.docs
          .map((doc) => ChatThread.fromFirestore(doc.data(), doc.id))
          .toList();
      threads.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return threads;
    });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    return _chatsCol
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<ChatMessage> sendMessage(
    String threadId,
    String senderId,
    String text,
  ) async {
    final now = DateTime.now();
    final messageCol = _chatsCol.doc(threadId).collection('messages');
    final docRef = messageCol.doc();

    // Determine receiver
    final threadDoc = await _chatsCol.doc(threadId).get();
    String receiverId = '';
    if (threadDoc.exists && threadDoc.data() != null) {
      final participants = List<String>.from(threadDoc.data()!['participants'] ?? []);
      receiverId = participants.firstWhere((id) => id != senderId, orElse: () => '');
    }

    final message = ChatMessage(
      id: docRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: now,
      status: MessageStatus.sent,
    );

    // Save message document
    await docRef.set(message.toFirestore());

    // Update parent thread metadata
    await _chatsCol.doc(threadId).set({
      'lastMessage': text,
      'lastMessageTime': now.millisecondsSinceEpoch,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    return message;
  }

  @override
  Future<ChatThread> getOrCreateThread(String userId1, String userId2) async {
    // Search existing threads where userId1 is a participant
    final snapshot =
        await _chatsCol.where('participants', arrayContains: userId1).get();

    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(userId2)) {
        return ChatThread.fromFirestore(doc.data(), doc.id);
      }
    }

    // Create a new thread if not found
    final docRef = _chatsCol.doc();
    final newThread = ChatThread(
      id: docRef.id,
      participantIds: [userId1, userId2],
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );

    await docRef.set(newThread.toFirestore());
    return newThread;
  }

  @override
  Future<void> markMessagesRead(String threadId, String userId) async {
    try {
      final unread = await _chatsCol
          .doc(threadId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('status', isNotEqualTo: 'read')
          .get();

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();

      await _chatsCol.doc(threadId).set({
        'unreadCount': 0,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
