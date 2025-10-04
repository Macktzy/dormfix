class MaintenanceRequest {
  final int? id;
  final String studentName;
  final String studentId;
  final String title;
  final String problemCategory;
  final String description;
  final String urgencyLevel; // keep consistent with DB
  final String status;
  final String? photoPath;
  final int? assignedStaff;
  final String roomNumber;
  final DateTime createdAt;
  final String? progressNotes;
  final DateTime? completedAt; // ✅ new field

  MaintenanceRequest({
    this.id,
    required this.studentName,
    required this.studentId,
    required this.title,
    required this.problemCategory,
    required this.description,
    required this.urgencyLevel,
    required this.status,
    this.photoPath,
    this.assignedStaff,
    required this.roomNumber,
    required this.createdAt,
    this.progressNotes,
    this.completedAt, // ✅ added
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'studentId': studentId,
      'title': title,
      'problemCategory': problemCategory,
      'description': description,
      'urgencyLevel': urgencyLevel,
      'status': status,
      'photoPath': photoPath,
      'assignedStaff': assignedStaff,
      'roomNumber': roomNumber,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'progressNotes': progressNotes,
      'completedAt': completedAt?.millisecondsSinceEpoch, // ✅ store as int
    };
  }

  static MaintenanceRequest fromMap(Map<String, dynamic> map) {
    return MaintenanceRequest(
      id: map['id'],
      studentName: map['studentName'],
      studentId: map['studentId'],
      title: map['title'],
      problemCategory: map['problemCategory'],
      description: map['description'],
      urgencyLevel: map['urgencyLevel'],
      status: map['status'],
      photoPath: map['photoPath'],
      assignedStaff: map['assignedStaff'] != null
          ? map['assignedStaff'] as int
          : null,
      roomNumber: map['roomNumber'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      progressNotes: map['progressNotes'],
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null, // ✅ convert back
    );
  }

  // ✅ Helper: copyWith to make updates easier
  MaintenanceRequest copyWith({
    int? id,
    String? studentName,
    String? studentId,
    String? title,
    String? problemCategory,
    String? description,
    String? urgencyLevel,
    String? status,
    String? photoPath,
    int? assignedStaff,
    String? roomNumber,
    DateTime? createdAt,
    String? progressNotes,
    DateTime? completedAt,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      problemCategory: problemCategory ?? this.problemCategory,
      description: description ?? this.description,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      roomNumber: roomNumber ?? this.roomNumber,
      createdAt: createdAt ?? this.createdAt,
      progressNotes: progressNotes ?? this.progressNotes,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
