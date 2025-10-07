class MaintenanceRequest {
  final int? id;
  final String studentName;
  final String studentId;
  final String title;
  final String problemCategory;
  final String description;
  final String urgencyLevel;
  final String status;
  final String? photoPath;
  final int? assignedStaff; // int4 in your DB
  final String roomNumber;
  final DateTime createdAt;
  final String? progressNotes;
  final DateTime? completedAt;

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
    this.completedAt,
  });

  /// Convert to database map - EXACT column names from YOUR screenshot
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentname': studentName, // ✅ All lowercase, no underscore
      'studentid': studentId, // ✅ All lowercase, no underscore
      'title': title,
      'problemcategory': problemCategory, // ✅ All lowercase, no underscore
      'description': description,
      'urgencylevel': urgencyLevel, // ✅ All lowercase, no underscore
      'status': status,
      'photopath': photoPath, // ✅ All lowercase, no underscore
      'assignedstaff': assignedStaff, // ✅ All lowercase, no underscore (int4)
      'roomnumber': roomNumber, // ✅ All lowercase, no underscore
      'createdat': createdAt
          .millisecondsSinceEpoch, // ✅ All lowercase, no underscore (int8/bigint)
      'progressnotes': progressNotes, // ✅ All lowercase, no underscore
      'completedat': completedAt
          ?.millisecondsSinceEpoch, // ✅ All lowercase, no underscore (int8)
    };
  }

  /// Create from database map - EXACT column names from YOUR screenshot
  static MaintenanceRequest fromMap(Map<String, dynamic> map) {
    return MaintenanceRequest(
      id: map['id'] as int?,
      studentName: map['studentname']?.toString() ?? '',
      studentId: map['studentid']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      problemCategory: map['problemcategory']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      urgencyLevel: map['urgencylevel']?.toString() ?? 'Low',
      status: map['status']?.toString() ?? 'Submitted',
      photoPath: map['photopath']?.toString(),
      assignedStaff: map['assignedstaff'] as int?,
      roomNumber: map['roomnumber']?.toString() ?? '',
      createdAt: map['createdat'] != null
          ? (map['createdat'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['createdat'])
                : DateTime.tryParse(map['createdat']?.toString() ?? '') ??
                      DateTime.now())
          : DateTime.now(),
      progressNotes: map['progressnotes']?.toString(),
      completedAt: map['completedat'] != null
          ? (map['completedat'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['completedat'])
                : DateTime.tryParse(map['completedat']?.toString() ?? ''))
          : null,
    );
  }

  /// Create a copy with modified fields
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

  @override
  String toString() {
    return 'MaintenanceRequest{id: $id, title: $title, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenanceRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
