enum UserType { student, admin, staff }

class User {
  final int? id;
  final String username; // used for login
  final String email;
  final String fullName;
  final String studentId; // staff ID
  final String password; // login password
  final UserType userType;
  final int assignedRequestsCount; // For staff workload tracking

  User({
    this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.studentId,
    required this.password,
    required this.userType,
    this.assignedRequestsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'studentId': studentId,
      'password': password,
      'userType': userType.toString(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      fullName: map['fullName'] as String,
      studentId: map['studentId'] as String,
      password: map['password'] as String,
      userType: UserType.values.firstWhere(
        (type) => type.toString() == map['userType'],
      ),
      assignedRequestsCount: map['assignedRequestsCount'] as int? ?? 0,
    );
  }
}
