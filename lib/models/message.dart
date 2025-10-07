class Message {
  final int? id;
  final String senderId; // senderid (no underscore) in DB
  final String receiverId; // receiverid (no underscore) in DB
  final String content;
  final DateTime timestamp;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  /// Convert Message to Map for SQLite - ALL LOWERCASE, NO UNDERSCORES
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderid': senderId, // ✅ All lowercase, no underscore (from screenshot)
      'receiverid':
          receiverId, // ✅ All lowercase, no underscore (from screenshot)
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Create Message from Map - ALL LOWERCASE, NO UNDERSCORES
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int?,
      senderId: map['senderid']?.toString() ?? '',
      receiverId: map['receiverid']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
                : DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
                      DateTime.now())
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, from: $senderId, to: $receiverId, at: $timestamp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
