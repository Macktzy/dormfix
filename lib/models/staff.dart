class Staff {
  final String id; // staff_id in Supabase
  final String name;
  final String username;
  final String password;
  final String role;
  final int assignedRequestsCount;
  final int highUrgencyCount;

  Staff({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.role = 'staff',
    this.assignedRequestsCount = 0,
    this.highUrgencyCount = 0,
  });

  String get availability => assignedRequestsCount >= 5 ? 'Busy' : 'Available';

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['staff_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: map['role']?.toString() ?? 'staff',
      assignedRequestsCount: map['assignedRequestsCount'] ?? 0,
      highUrgencyCount: map['highUrgencyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staff_id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'assignedRequestsCount': assignedRequestsCount,
      'highUrgencyCount': highUrgencyCount,
    };
  }
}
