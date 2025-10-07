import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/request.dart';

class StaffHomeScreen extends StatefulWidget {
  final int staffId; // Changed to int - uses staff.id (numeric)
  final String staffUsername;

  const StaffHomeScreen({
    super.key,
    required this.staffId,
    required this.staffUsername,
  });

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  late Future<List<MaintenanceRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService().getRequestsAssignedTo(widget.staffId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = SupabaseService().getRequestsAssignedTo(widget.staffId);
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snap.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No tasks assigned.',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
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
                    title: Text(
                      '${r.problemCategory} • ${r.status}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
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
    switch (status.toLowerCase()) {
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'in progress':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      default:
        return const Icon(Icons.pending, color: Colors.grey);
    }
  }
}

// ==================== TaskDetailsScreen ====================

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
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _completionPhoto = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    setState(() => _isUpdating = true);

    try {
      String? photoUrl;

      // Upload photo if one was selected
      if (_completionPhoto != null) {
        final fileName =
            'completion_${widget.request.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoUrl = await SupabaseService().uploadPhoto(
          _completionPhoto!.path,
          fileName,
        );
      }

      // Create updated request
      final updatedRequest = widget.request.copyWith(
        status: newStatus,
        photoPath: photoUrl ?? widget.request.photoPath,
        progressNotes: _progressNoteController.text.trim().isNotEmpty
            ? _progressNoteController.text.trim()
            : widget.request.progressNotes,
        completedAt: newStatus == 'Completed' ? DateTime.now() : null,
      );

      // Update in database
      await SupabaseService().updateRequest(
        widget.request.id!,
        updatedRequest.toMap(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

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
      if (mounted) setState(() => _isUpdating = false);
    }
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
                        widget.request.photoPath!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Issue Photo:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.request.photoPath!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('Image failed to load'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

                      // Progress Note
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

                      // Upload Completion Photo
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
                                          color: Colors.white,
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
                                        color: Colors.white,
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
