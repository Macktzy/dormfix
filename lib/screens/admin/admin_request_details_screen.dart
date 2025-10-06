import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import '../../models/request.dart';
import '../../models/student.dart';
import '../../models/staff.dart';
import 'admin_chat_screen.dart';

class AdminRequestDetailsScreen extends StatefulWidget {
  final MaintenanceRequest request;
  final VoidCallback onRequestUpdated;

  const AdminRequestDetailsScreen({
    super.key,
    required this.request,
    required this.onRequestUpdated,
  });

  @override
  State<AdminRequestDetailsScreen> createState() =>
      _AdminRequestDetailsScreenState();
}

class _AdminRequestDetailsScreenState extends State<AdminRequestDetailsScreen> {
  String? _selectedStaffId; // Changed from int? to String?
  Student? _reporter;
  List<Staff> _allStaff = [];

  @override
  void initState() {
    super.initState();
    // Convert int to String if assignedStaff is not null
    _selectedStaffId = widget.request.assignedStaff?.toString();
    _loadStudentInfo();
    _loadStaff();
  }

  Future<void> _loadStudentInfo() async {
    final studentMap = await SupabaseService().getStudentById(
      widget.request.studentId,
    );
    if (studentMap == null || !mounted) return;

    setState(() => _reporter = Student.fromMap(studentMap));
  }

  Future<void> _loadStaff() async {
    final staffList = await SupabaseService().getAllStaff();
    if (!mounted) return;
    setState(() => _allStaff = staffList);
  }

  Future<void> _assignOrChangeStaff() async {
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a staff member")),
      );
      return;
    }

    final oldStaff = widget.request.assignedStaff;

    // Convert String staff ID to int for the request
    final updatedRequest = widget.request.copyWith(
      assignedStaff: int.tryParse(_selectedStaffId!),
      status: "Assigned",
    );

    await SupabaseService().updateRequest(
      widget.request.id!,
      updatedRequest.toMap(),
    );

    if (!mounted) return;

    // Safe helper for getting staff name
    Staff getStaffById(String? id) {
      if (id == null) {
        return Staff(
          id: '0',
          name: "Unknown",
          role: "Unassigned",
          username: '',
          password: '',
        );
      }
      return _allStaff.firstWhere(
        (s) => s.id == id,
        orElse: () => Staff(
          id: '0',
          name: "Unknown",
          role: "Unassigned",
          username: '',
          password: '',
        ),
      );
    }

    final newStaffName = getStaffById(_selectedStaffId).name;
    final oldStaffName = getStaffById(oldStaff?.toString()).name;

    if (oldStaff == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Task assigned to $newStaffName")));
    } else if (oldStaff.toString() != _selectedStaffId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Task reassigned from $oldStaffName to $newStaffName"),
        ),
      );
    }

    widget.onRequestUpdated();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Urgency: ${request.urgencyLevel}",
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(request.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              "Created at: ${DateFormat('yyyy-MM-dd HH:mm').format(request.createdAt)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            if (_reporter != null) ...[
              Text(
                "Reporter Information",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Name: ${_reporter!.name}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "ID: ${_reporter!.id}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatScreen(
                        staffId: "STAFF001",
                        studentId: widget.request.studentId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text("Message Student"),
              ),
            ] else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 20),

            if (request.photoPath != null && request.photoPath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  request.photoPath!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    "Image failed to load",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              const Text("No image provided"),

            const SizedBox(height: 20),

            if (_allStaff.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedStaffId != null &&
                        _allStaff.any((staff) => staff.id == _selectedStaffId)
                    ? _selectedStaffId
                    : null,
                items: _allStaff
                    .map(
                      (staff) => DropdownMenuItem<String>(
                        value: staff.id,
                        child: Text("${staff.name} (${staff.availability})"),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Select Staff",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedStaffId = value),
              )
            else
              const Text("No staff available"),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _assignOrChangeStaff,
              icon: const Icon(Icons.check),
              label: Text(
                request.assignedStaff == null ? "Assign Staff" : "Change Staff",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
