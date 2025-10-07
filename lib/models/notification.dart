// lib/models/notification.dart
class AppNotification {
  final int? id;
  final String recipientId; // staff ID or admin ID
  final String senderId;
  final String type; // 'task_assigned', 'task_update', 'message', 'urgent'
  final String title;
  final String message;
  final String? relatedRequestId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedRequestId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientid': recipientId,
      'senderid': senderId,
      'type': type,
      'title': title,
      'message': message,
      'relatedrequestid': relatedRequestId,
      'isread': isRead ? 1 : 0,
      'createdat': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      recipientId: map['recipientid']?.toString() ?? '',
      senderId: map['senderid']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      relatedRequestId: map['relatedrequestid']?.toString(),
      isRead: (map['isread'] ?? 0) == 1,
      createdAt: map['createdat'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdat'])
          : DateTime.now(),
    );
  }

  AppNotification copyWith({
    int? id,
    String? recipientId,
    String? senderId,
    String? type,
    String? title,
    String? message,
    String? relatedRequestId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedRequestId: relatedRequestId ?? this.relatedRequestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
