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
  int? _selectedStaffId; // Changed to int
  Student? _reporter;
  List<Staff> _allStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.request.assignedStaff; // Already int?
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_loadStudentInfo(), _loadStaff()]);
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        const SnackBar(
          content: Text("Please select a staff member"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final oldStaff = widget.request.assignedStaff;

      // Update request with new staff assignment (using INTEGER id)
      final updatedRequest = widget.request.copyWith(
        assignedStaff: _selectedStaffId,
        status: "Assigned",
      );

      await SupabaseService().updateRequest(
        widget.request.id!,
        updatedRequest.toMap(),
      );

      if (!mounted) return;

      // Get staff name for message
      final newStaffName = _allStaff
          .firstWhere(
            (s) => s.id == _selectedStaffId,
            orElse: () => Staff(
              id: 0,
              staffId: '',
              name: "Unknown",
              username: '',
              password: '',
            ),
          )
          .name;

      if (oldStaff == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Task assigned to $newStaffName"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (oldStaff != _selectedStaffId) {
        final oldStaffName = _allStaff
            .firstWhere(
              (s) => s.id == oldStaff,
              orElse: () => Staff(
                id: 0,
                staffId: '',
                name: "Previous Staff",
                username: '',
                password: '',
              ),
            )
            .name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Task reassigned from $oldStaffName to $newStaffName",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onRequestUpdated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning staff: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Request Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final request = widget.request;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Urgency Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          color: _getUrgencyColor(request.urgencyLevel),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Urgency: ${request.urgencyLevel}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getUrgencyColor(request.urgencyLevel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Request Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow('Category:', request.problemCategory),
                    _buildDetailRow('Room:', request.roomNumber),
                    _buildDetailRow('Status:', request.status),
                    _buildDetailRow(
                      'Created:',
                      DateFormat('yyyy-MM-dd HH:mm').format(request.createdAt),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(request.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Student Information Card
            if (_reporter != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildDetailRow('Name:', _reporter!.name),
                      _buildDetailRow('ID:', _reporter!.id),
                      _buildDetailRow('Room:', _reporter!.roomNumber),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminChatScreen(
                                  staffId: "admin",
                                  studentId: widget.request.studentId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message),
                          label: const Text("Message Student"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Photo Card
            if (request.photoPath != null && request.photoPath!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attached Photo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          request.photoPath!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 8),
                                    Text("Image failed to load"),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Staff Assignment Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Assignment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    if (_allStaff.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value:
                            _selectedStaffId != null &&
                                _allStaff.any(
                                  (staff) => staff.id == _selectedStaffId,
                                )
                            ? _selectedStaffId
                            : null,
                        items: _allStaff
                            .map(
                              (staff) => DropdownMenuItem<int>(
                                value: staff.id, // Use integer ID
                                child: Text(
                                  "${staff.name} (${staff.availability})",
                                ),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: "Select Staff Member",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (value) =>
                            setState(() => _selectedStaffId = value),
                      )
                    else
                      const Text(
                        "No staff members available",
                        style: TextStyle(color: Colors.red),
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _allStaff.isEmpty
                            ? null
                            : _assignOrChangeStaff,
                        icon: const Icon(Icons.check),
                        label: Text(
                          request.assignedStaff == null
                              ? "Assign Staff"
                              : "Change Staff",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
