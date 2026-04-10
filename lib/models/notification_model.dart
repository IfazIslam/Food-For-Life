import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String targetUid;
  final String senderUid;  // NEW: to show who sent the request
  final String? chatId;    // NEW: to perform Accept/Decline actions
  final String title;
  final String body;
  final String type; // e.g., 'chat_request', 'food_granted', 'request'
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.targetUid,
    required this.senderUid,
    this.chatId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetUid': targetUid,
      'senderUid': senderUid,
      'chatId': chatId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      targetUid: map['targetUid'] ?? '',
      senderUid: map['senderUid'] ?? '',
      chatId: map['chatId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
