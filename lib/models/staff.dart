// lib/models/staff.dart
class Staff {
  final String id;
  final String name;
  final int assignedRequestsCount;
  final int highUrgencyCount; // New field for high-urgency tasks

  Staff({
    required this.id,
    required this.name,
    this.assignedRequestsCount = 0,
    this.highUrgencyCount = 0,
  });

  // Determine availability based on assigned requests
  String get availability {
    return assignedRequestsCount >= 5 ? 'Busy' : 'Available';
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'],
      name: map['name'],
      assignedRequestsCount: map['assignedRequestsCount'] ?? 0,
      highUrgencyCount: map['highUrgencyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'assignedRequestsCount': assignedRequestsCount,
      'highUrgencyCount': highUrgencyCount,
    };
  }
}
