import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request.dart';
import '../models/message.dart';
import '../models/student.dart';
import '../models/staff.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------- AUTH ----------------------
  // Add these methods to your SupabaseService class (after the STUDENTS section)

  // ---------------------- AUTHENTICATION ----------------------

  /// Authenticate admin/staff user by username and password
  /// Returns null if credentials are invalid
  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Add this method after your getAllStaff() method
  Future<void> addStaff({
    required String username,
    required String password,
    required String fullName,
  }) async {
    try {
      await _client.from('staff').insert({
        'username': username,
        'password': password,
        'name': fullName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding staff: $e');
      throw Exception('Failed to add staff: $e');
    }
  }

  /// Authenticate student by student ID and password
  /// Returns Student object if credentials are valid, null otherwise
  Future<Student?> authenticateStudent(
    String studentId,
    String password,
  ) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('student_id', studentId)
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
  Future<Staff?> authenticateStaff(String username, String password) async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .or('username.eq.$username,staff_id.eq.$username')
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
  Future<List<MaintenanceRequest>> getAllRequests() async {
    final data = await _client
        .from('requests')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<MaintenanceRequest>> getRequestsByStudent(
    String studentId,
  ) async {
    final data = await _client
        .from('requests')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertRequest(MaintenanceRequest r) async {
    await _client.from('requests').insert(r.toMap());
  }

  Future<void> createRequest(MaintenanceRequest r) async => insertRequest(r);

  Future<List<MaintenanceRequest>> getRequestsByStudentId(
    String studentId,
  ) async {
    try {
      final data = await _client
          .from('requests')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching requests by student ID: $e');
      return [];
    }
  }

  Future<List<MaintenanceRequest>> getRequestsAssignedTo(String staffId) async {
    try {
      final data = await _client
          .from('requests')
          .select()
          .eq('assigned_to', staffId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((m) => MaintenanceRequest.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching requests assigned to staff: $e');
      return [];
    }
  }

  Future<void> updateRequest(int id, Map<String, dynamic> changes) async {
    await _client.from('requests').update(changes).eq('id', id);
  }

  Future<void> updateRequestObject(MaintenanceRequest request) async {
    await updateRequest(request.id!, request.toMap());
  }

  // ---------------------- STUDENTS ----------------------
  Future<List<Student>> getStudents() async {
    final data = await _client.from('students').select();
    return (data as List)
        .map((m) => Student.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    final response = await _client
        .from('students')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    return response;
  }

  Future<void> createStudent({
    required String studentId,
    required String studentName,
    required String username,
    required String password,
    required String roomNumber,
  }) async {
    await _client.from('students').insert({
      'student_id': studentId,
      'student_name': studentName,
      'username': username,
      'password': password,
      'room_number': roomNumber,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ---------------------- STAFF ----------------------
  Future<List<Staff>> getStaffs() async {
    final data = await _client.from('staff').select();
    return (data as List)
        .map((m) => Staff.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<Staff>> getAllStaff() async => getStaffs();

  // ---------------------- MESSAGES ----------------------
  Future<List<Message>> getConversation(String user1Id, String user2Id) async {
    final data = await _client
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$user1Id,receiver_id.eq.$user2Id),and(sender_id.eq.$user2Id,receiver_id.eq.$user1Id)',
        )
        .order('timestamp', ascending: true);

    return (data as List)
        .map((m) => Message.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(Message msg) async {
    await _client.from('messages').insert(msg.toMap());
  }
}
