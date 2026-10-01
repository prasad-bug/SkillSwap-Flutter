import 'package:equatable/equatable.dart';

/// Status of a chat message.
enum MessageStatus {
  sent,
  delivered,
  read;

  static MessageStatus fromString(String v) => MessageStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => MessageStatus.sent,
      );
}

/// A single chat message.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: MessageStatus.fromString((map['status'] as String?) ?? 'sent'),
    );
  }

  @override
  List<Object?> get props => [id, senderId, text, timestamp, status];
}

/// A chat thread between two users.
class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.participantIds,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatThread copyWith({
    String? id,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    return ChatThread(
      id: map['id'] as String,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessage: (map['lastMessage'] as String?) ?? '',
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'] as int)
          : null,
      unreadCount: (map['unreadCount'] as int?) ?? 0,
    );
  }

  String otherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
  }

  @override
  List<Object?> get props =>
      [id, participantIds, lastMessage, lastMessageAt, unreadCount];
}
