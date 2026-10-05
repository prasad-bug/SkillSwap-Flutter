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
    this.receiverId = '',
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': text,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    DateTime ts;
    final rawTs = map['timestamp'];
    if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs != null && rawTs.toString().contains('Timestamp')) {
      ts = DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return ChatMessage(
      id: (map['id'] ?? '') as String,
      senderId: (map['senderId'] ?? '') as String,
      receiverId: (map['receiverId'] ?? '') as String,
      text: (map['message'] ?? map['text'] ?? '') as String,
      timestamp: ts,
      status: MessageStatus.fromString((map['status'] as String?) ?? 'sent'),
    );
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String docId) {
    return ChatMessage.fromMap({
      'id': docId,
      ...data,
    });
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

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participantIds,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageAt?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    DateTime? lastMsg;
    final rawTime = map['lastMessageAt'] ?? map['lastMessageTime'];
    if (rawTime is int) {
      lastMsg = DateTime.fromMillisecondsSinceEpoch(rawTime);
    }

    return ChatThread(
      id: (map['id'] ?? '') as String,
      participantIds: List<String>.from(map['participantIds'] ?? map['participants'] ?? []),
      lastMessage: (map['lastMessage'] as String?) ?? '',
      lastMessageAt: lastMsg,
      unreadCount: (map['unreadCount'] as int?) ?? 0,
    );
  }

  factory ChatThread.fromFirestore(Map<String, dynamic> data, String docId) {
    return ChatThread.fromMap({
      'id': docId,
      ...data,
    });
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
