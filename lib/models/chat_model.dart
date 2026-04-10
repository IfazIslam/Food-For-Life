import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ChatModel {
  final String chatId;
  final List<String> participants;
  final List<ChatMessage> messages;
  final String? feedIdRequested;
  final bool accepted;
  final bool completed;
  final String status;       // 'pending' or 'accepted'
  final String initiatorUid; // who sent the chat request

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.messages,
    this.feedIdRequested,
    this.accepted = false,
    this.completed = false,
    this.status = 'accepted',
    this.initiatorUid = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'messages': messages.map((m) => m.toMap()).toList(),
      'feedIdRequested': feedIdRequested,
      'accepted': accepted,
      'completed': completed,
      'status': status,
      'initiatorUid': initiatorUid,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      chatId: id,
      participants: List<String>.from(map['participants'] ?? []),
      messages: (map['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m)))
              .toList() ??
          [],
      feedIdRequested: map['feedIdRequested'],
      accepted: map['accepted'] ?? false,
      completed: map['completed'] ?? false,
      status: map['status'] ?? 'accepted',
      initiatorUid: map['initiatorUid'] ?? '',
    );
  }
}
