class Student {
  final String id; // student_id in database
  final String name; // student_name in database
  final String username;
  final String password;
  final String roomNumber; // room_number in database
  final DateTime? createdAt; // created_at in database

  Student({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.roomNumber = '',
    this.createdAt,
  });

  /// Convert Student to Map for database - Uses snake_case with underscores
  Map<String, dynamic> toMap() {
    return {
      'student_id': id, // ✅ snake_case (from screenshot)
      'student_name': name, // ✅ snake_case (from screenshot)
      'username': username,
      'password': password,
      'room_number': roomNumber, // ✅ snake_case (from screenshot)
      'created_at':
          createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch, // ✅ snake_case, bigint
    };
  }

  /// Create Student from database Map - Uses snake_case with underscores
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['student_id']?.toString() ?? '',
      name: map['student_name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      roomNumber: map['room_number']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
                : DateTime.tryParse(map['created_at']?.toString() ?? ''))
          : null,
    );
  }

  /// Create a copy of Student with some values updated
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
    return 'Student{id: $id, name: $name, username: $username, roomNumber: $roomNumber}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
