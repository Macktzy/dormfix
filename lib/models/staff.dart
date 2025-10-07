class Staff {
  final int? id; // bigint id
  final String staffId; // staff_id (snake_case in DB)
  final String name;
  final String username;
  final String password;
  final String role;
  final int assignedRequestsCount; // camelCase in DB
  final int highUrgencyCount; // camelCase in DB
  final DateTime? createdAt; // createdat (lowercase) in DB

  Staff({
    this.id,
    required this.staffId,
    required this.name,
    required this.username,
    required this.password,
    this.role = 'staff',
    this.assignedRequestsCount = 0,
    this.highUrgencyCount = 0,
    this.createdAt,
  });

  String get availability => assignedRequestsCount >= 5 ? 'Busy' : 'Available';

  /// Create Staff from database map - MIXED naming from YOUR screenshot
  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as int?,
      staffId:
          map['staff_id']?.toString() ?? '', // ✅ snake_case (from screenshot)
      name: map['name']?.toString() ?? 'Unknown',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: map['role']?.toString() ?? 'staff',
      assignedRequestsCount:
          (map['assignedRequestsCount'] ?? 0)
              as int, // ✅ camelCase (from screenshot)
      highUrgencyCount:
          (map['highUrgencyCount'] ?? 0)
              as int, // ✅ camelCase (from screenshot)
      createdAt:
          map['createdat'] !=
              null // ✅ lowercase, no underscore (from screenshot)
          ? (map['createdat'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['createdat'])
                : DateTime.tryParse(map['createdat']?.toString() ?? ''))
          : null,
    );
  }

  /// Convert Staff to database map - MIXED naming from YOUR screenshot
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staff_id': staffId, // ✅ snake_case
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'assignedRequestsCount': assignedRequestsCount, // ✅ camelCase
      'highUrgencyCount': highUrgencyCount, // ✅ camelCase
      'createdat':
          createdAt?.millisecondsSinceEpoch, // ✅ lowercase, no underscore
    };
  }

  /// Create a copy with modified fields
  Staff copyWith({
    int? id,
    String? staffId,
    String? name,
    String? username,
    String? password,
    String? role,
    int? assignedRequestsCount,
    int? highUrgencyCount,
    DateTime? createdAt,
  }) {
    return Staff(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      assignedRequestsCount:
          assignedRequestsCount ?? this.assignedRequestsCount,
      highUrgencyCount: highUrgencyCount ?? this.highUrgencyCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Staff{staffId: $staffId, name: $name, username: $username, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Staff && other.staffId == staffId;
  }

  @override
  int get hashCode => staffId.hashCode;
}
