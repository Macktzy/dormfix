import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request.dart';
import '../models/message.dart';
import '../models/student.dart';
import '../models/staff.dart';
import 'dart:io';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------- AUTHENTICATION ----------------------

  /// Authenticate admin user by username and password
  Future<Map<String, dynamic>?> authenticateAdmin(
    String username,
    String password,
  ) async {
    try {
      final response = await _client
          .from('admins')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error authenticating admin: $e');
      return null;
    }
  }

  /// Authenticate student by student ID or username and password
  Future<Student?> authenticateStudent(
    String identifier,
    String password,
  ) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .or('student_id.eq.$identifier,username.eq.$identifier')
          .eq('password', password)
          .maybeSingle();

      if (response == null) return null;
      return Student.fromMap(response);
    } catch (e) {
      print('Error authenticating student: $e');
      return null;
    }
  }

  /// Authenticate staff by username or staff_id and password
  Future<Staff?> authenticateStaff(String identifier, String password) async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .or('username.eq.$identifier,staff_id.eq.$identifier')
          .eq('password', password)
          .maybeSingle();

      if (response == null) return null;
      return Staff.fromMap(response);
    } catch (e) {
      print('Error authenticating staff: $e');
      return null;
    }
  }

  // ---------------------- REQUESTS ----------------------

  /// Get all maintenance requests (for admin)
  Future<List<MaintenanceRequest>> getAllRequests() async {
    try {
      final data = await _client
          .from('requests')
          .select()
          .order('createdat', ascending: false);

      return (data as List)
          .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all requests: $e');
      return [];
    }
  }

  /// Get requests for a specific student
  Future<List<MaintenanceRequest>> getRequestsByStudentId(
    String studentId,
  ) async {
    try {
      final data = await _client
          .from('requests')
          .select()
          .eq('studentid', studentId)
          .order('createdat', ascending: false);

      return (data as List)
          .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching requests by student ID: $e');
      return [];
    }
  }

  /// Get requests assigned to a specific staff member
  /// Accepts both int and String, converts to int for database query
  Future<List<MaintenanceRequest>> getRequestsAssignedTo(
    dynamic staffId,
  ) async {
    try {
      // Convert to int if it's a String
      final int staffIntId = staffId is int
          ? staffId
          : int.parse(staffId.toString());

      final data = await _client
          .from('requests')
          .select()
          .eq('assignedstaff', staffIntId)
          .order('createdat', ascending: false);

      return (data as List)
          .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching requests assigned to staff: $e');
      return [];
    }
  }

  /// Create a new maintenance request
  /// Create a new maintenance request
  Future<void> createRequest(MaintenanceRequest request) async {
    try {
      // Don't include id when creating - let database auto-generate it
      final requestData = request.toMap(includeId: false);
      await _client.from('requests').insert(requestData);
    } catch (e) {
      print('Error creating request: $e');
      throw Exception('Failed to create request: $e');
    }
  }

  /// Update an existing request
  Future<void> updateRequest(int id, Map<String, dynamic> changes) async {
    try {
      await _client.from('requests').update(changes).eq('id', id);
    } catch (e) {
      print('Error updating request: $e');
      throw Exception('Failed to update request: $e');
    }
  }

  /// Update request using MaintenanceRequest object
  Future<void> updateRequestObject(MaintenanceRequest request) async {
    if (request.id == null) {
      throw Exception('Cannot update request without ID');
    }
    await updateRequest(request.id!, request.toMap());
  }

  // ---------------------- STUDENTS ----------------------

  /// Get all students
  Future<List<Student>> getStudents() async {
    try {
      final data = await _client.from('students').select();
      return (data as List)
          .map((m) => Student.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  /// Get a specific student by ID
  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching student by ID: $e');
      return null;
    }
  }

  /// Create a new student account
  Future<void> createStudent({
    required String studentId,
    required String studentName,
    required String username,
    required String password,
    required String roomNumber,
  }) async {
    try {
      await _client.from('students').insert({
        'student_id': studentId,
        'student_name': studentName,
        'username': username,
        'password': password,
        'room_number': roomNumber,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error creating student: $e');
      throw Exception('Failed to create student: $e');
    }
  }

  // ---------------------- STAFF ----------------------

  /// Get all staff members
  Future<List<Staff>> getAllStaff() async {
    try {
      final data = await _client.from('staff').select();
      return (data as List)
          .map((m) => Staff.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }

  /// Get staff by numeric ID
  Future<Staff?> getStaffById(int staffId) async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .eq('id', staffId)
          .maybeSingle();

      if (response == null) return null;
      return Staff.fromMap(response);
    } catch (e) {
      print('Error fetching staff by ID: $e');
      return null;
    }
  }

  /// Add a new staff member
  Future<void> addStaff({
    required String username,
    required String password,
    required String fullName,
    required String staffId,
  }) async {
    try {
      await _client.from('staff').insert({
        'staff_id': staffId,
        'username': username,
        'password': password,
        'name': fullName,
        'createdat': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error adding staff: $e');
      throw Exception('Failed to add staff: $e');
    }
  }

  // ---------------------- MESSAGES ----------------------

  /// Get conversation between two users
  Future<List<Message>> getConversation(String user1Id, String user2Id) async {
    try {
      final data = await _client
          .from('messages')
          .select()
          .or(
            'and(senderid.eq.$user1Id,receiverid.eq.$user2Id),and(senderid.eq.$user2Id,receiverid.eq.$user1Id)',
          )
          .order('timestamp', ascending: true);

      return (data as List)
          .map((m) => Message.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching conversation: $e');
      return [];
    }
  }

  /// Send a message
  Future<void> sendMessage(Message msg) async {
    try {
      await _client.from('messages').insert(msg.toMap());
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // ---------------------- PHOTO UPLOAD ----------------------

  /// Upload photo to Supabase Storage
  Future<String?> uploadPhoto(String filePath, String fileName) async {
    try {
      final file = File(filePath);

      // Upload to Supabase Storage
      await _client.storage.from('maintenance-photos').upload(fileName, file);

      // Get public URL
      final publicUrl = _client.storage
          .from('maintenance-photos')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// Delete photo from Supabase Storage
  Future<void> deletePhoto(String fileName) async {
    try {
      await _client.storage.from('maintenance-photos').remove([fileName]);
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }
}
