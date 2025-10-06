class Student {
  final String id; // Maps to student_id in database
  final String name; // Maps to student_name in database
  final String username; // Maps to username in database
  final String password;
  final String roomNumber; // Maps to room_number in database
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.roomNumber = '',
    this.createdAt,
  });

  // Convert Student to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'student_id': id, // Database column name
      'student_name': name, // Database column name
      'username': username,
      'password': password,
      'room_number': roomNumber, // Database column name
      'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  // Create Student from Map (from database)
  factory Student.fromMap(Map<String, dynamic> map) {
    DateTime? parsedCreatedAt;
    final createdValue = map['created_at'];

    if (createdValue != null) {
      if (createdValue is int) {
        // Supabase bigint timestamp in milliseconds
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdValue);
      } else if (createdValue is String) {
        // ISO8601 string timestamp
        parsedCreatedAt = DateTime.tryParse(createdValue);
      }
    }

    return Student(
      id: map['student_id']?.toString() ?? '',
      name: map['student_name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      roomNumber: map['room_number']?.toString() ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  // Create a copy of Student with some values updated
  Student copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    String? roomNumber,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      roomNumber: roomNumber ?? this.roomNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Student{id: $id, name: $name, username: $username, roomNumber: $roomNumber, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
