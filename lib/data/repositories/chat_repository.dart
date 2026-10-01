import '../models/chat.dart';

/// Abstract interface for chat operations.
abstract class ChatRepository {
  /// Stream all threads for a user.
  Stream<List<ChatThread>> watchThreadsForUser(String userId);

  /// Stream messages for a thread.
  Stream<List<ChatMessage>> watchMessages(String threadId);

  /// Send a message (returns the sent message).
  Future<ChatMessage> sendMessage(String threadId, String senderId, String text);

  /// Get or create a thread between two users.
  Future<ChatThread> getOrCreateThread(String userId1, String userId2);

  /// Mark messages as read.
  Future<void> markMessagesRead(String threadId, String userId);
}
