import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../models/request.dart';

class StaffHomeScreen extends StatefulWidget {
  final int staffId; // Changed from staffUsername to staffId
  final String staffUsername; // Optional: keep for display

  const StaffHomeScreen({
    super.key,
    required this.staffId,
    required this.staffUsername, // keep for AppBar display
  });

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  late Future<List<MaintenanceRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService().getRequestsAssignedTo(
      widget.staffId.toString(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = SupabaseService().getRequestsAssignedTo(
        widget.staffId.toString(),
      );
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openTaskDetails(MaintenanceRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TaskDetailsScreen(request: request, onTaskUpdated: _refresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff: ${widget.staffUsername}'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<List<MaintenanceRequest>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No tasks assigned.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('${r.problemCategory} • ${r.status}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room: ${r.roomNumber}'),
                        Text('Urgency: ${r.urgencyLevel}'),
                        Text(r.description),
                      ],
                    ),
                    trailing: _buildStatusIndicator(r.status),
                    onTap: () => _openTaskDetails(r),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    switch (status) {
      case 'Completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'In Progress':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      default:
        return const Icon(Icons.pending, color: Colors.grey);
    }
  }
}

// TaskDetailsScreen remains unchanged

class TaskDetailsScreen extends StatefulWidget {
  final MaintenanceRequest request;
  final VoidCallback onTaskUpdated;

  const TaskDetailsScreen({
    super.key,
    required this.request,
    required this.onTaskUpdated,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TextEditingController _progressNoteController = TextEditingController();
  File? _completionPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isUpdating = false;

  @override
  void dispose() {
    _progressNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _completionPhoto = File(image.path);
      });
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Create updated request
      final updatedRequest = MaintenanceRequest(
        id: widget.request.id,
        studentName: widget.request.studentName,
        studentId: widget.request.studentId,
        title: widget.request.title,
        problemCategory: widget.request.problemCategory,
        description: widget.request.description,
        urgencyLevel: widget.request.urgencyLevel,
        status: newStatus,
        photoPath: _completionPhoto?.path ?? widget.request.photoPath,
        assignedStaff: widget.request.assignedStaff,
        createdAt: widget.request.createdAt,
        roomNumber: widget.request.roomNumber,
      );

      // Update in database - pass id and updated request map
      await SupabaseService().updateRequest(
        widget.request.id!, // Pass the ID as first argument (assert non-null)
        updatedRequest.toMap(), // Convert to Map<String, dynamic>
      );

      // Notify admin of progress
      await _notifyAdminOfProgress(updatedRequest);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh parent screen and go back
      widget.onTaskUpdated();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _notifyAdminOfProgress(MaintenanceRequest request) async {
    // Implement your admin notification logic here
    // This could be a push notification, email, or database entry
    print('Notifying admin of progress for task ${request.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Issue Description:',
                      widget.request.description,
                    ),
                    _buildInfoRow('Student Name:', widget.request.studentName),
                    _buildInfoRow('Room:', widget.request.roomNumber),
                    _buildInfoRow(
                      'Urgency Level:',
                      widget.request.urgencyLevel,
                    ),
                    _buildInfoRow('Current Status:', widget.request.status),
                    if (widget.request.photoPath != null &&
                        widget.request.photoPath!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Issue Photo:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Image.file(
                            File(widget.request.photoPath!),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Update Section
            if (widget.request.status != 'Completed') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Task',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Progress Note (Optional)
                      TextField(
                        controller: _progressNoteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Add Progress Note (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Describe what work has been done...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upload Completion Photo (Optional)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Upload Photo'),
                          ),
                          if (_completionPhoto != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check, color: Colors.green),
                            const Text('Photo selected'),
                          ],
                        ],
                      ),

                      if (_completionPhoto != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.file(
                            _completionPhoto!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          if (widget.request.status != 'In Progress')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isUpdating
                                    ? null
                                    : () => _updateTaskStatus('In Progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isUpdating
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Mark In Progress'),
                              ),
                            ),
                          if (widget.request.status != 'In Progress')
                            const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateTaskStatus('Completed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: _isUpdating
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Mark Completed'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Task Completed Message
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(width: 8),
                      Text(
                        'This task has been completed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
