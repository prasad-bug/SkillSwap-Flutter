import 'dart:async';
import '../models/chat.dart';
import '../repositories/chat_repository.dart';
import '../mock_data/mock_data.dart';
import 'package:uuid/uuid.dart';

/// In-memory mock implementation of [ChatRepository].
class MockChatRepository implements ChatRepository {
  MockChatRepository() {
    // Deep-copy mock messages
    for (final entry in MockData.messages.entries) {
      _messages[entry.key] = List.from(entry.value);
      _messageControllers[entry.key] =
          StreamController<List<ChatMessage>>.broadcast();
    }
    _threadController = StreamController<List<ChatThread>>.broadcast();
    _threads = List.from(MockData.threads);
  }

  late StreamController<List<ChatThread>> _threadController;
  late List<ChatThread> _threads;
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, StreamController<List<ChatMessage>>> _messageControllers =
      {};
  final _uuid = const Uuid();

  @override
  Stream<List<ChatThread>> watchThreadsForUser(String userId) {
    Future.microtask(() {
      _threadController.add(
        _threads
            .where((t) => t.participantIds.contains(userId))
            .toList()
          ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
              .compareTo(a.lastMessageAt ?? DateTime(0))),
      );
    });
    return _threadController.stream.map(
      (threads) => threads
          .where((t) => t.participantIds.contains(userId))
          .toList()
        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
            .compareTo(a.lastMessageAt ?? DateTime(0))),
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    if (!_messageControllers.containsKey(threadId)) {
      _messageControllers[threadId] =
          StreamController<List<ChatMessage>>.broadcast();
      _messages[threadId] = [];
    }
    Future.microtask(() {
      _messageControllers[threadId]!
          .add(List.from(_messages[threadId] ?? []));
    });
    return _messageControllers[threadId]!.stream;
  }

  @override
  Future<ChatMessage> sendMessage(
      String threadId, String senderId, String text) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    if (!_messages.containsKey(threadId)) {
      _messages[threadId] = [];
      _messageControllers[threadId] =
          StreamController<List<ChatMessage>>.broadcast();
    }

    _messages[threadId]!.add(msg);
    _messageControllers[threadId]?.add(List.from(_messages[threadId]!));

    // Update thread
    final tIdx = _threads.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      _threads[tIdx] = _threads[tIdx].copyWith(
        lastMessage: text,
        lastMessageAt: msg.timestamp,
      );
      _threadController.add(List.from(_threads));
    }

    return msg;
  }

  @override
  Future<ChatThread> getOrCreateThread(
      String userId1, String userId2) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _threads.where((t) =>
        t.participantIds.contains(userId1) &&
        t.participantIds.contains(userId2));
    if (existing.isNotEmpty) return existing.first;

    final newThread = ChatThread(
      id: _uuid.v4(),
      participantIds: [userId1, userId2],
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );
    _threads.add(newThread);
    _messages[newThread.id] = [];
    _messageControllers[newThread.id] =
        StreamController<List<ChatMessage>>.broadcast();
    _threadController.add(List.from(_threads));
    return newThread;
  }

  @override
  Future<void> markMessagesRead(String threadId, String userId) async {
    final tIdx = _threads.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      _threads[tIdx] = _threads[tIdx].copyWith(unreadCount: 0);
      _threadController.add(List.from(_threads));
    }
  }

  void dispose() {
    _threadController.close();
    for (final c in _messageControllers.values) {
      c.close();
    }
  }
}
