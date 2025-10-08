import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/request.dart';
import '../../constants/app_constants.dart';
import '../student/student_chat_screen.dart';

class StaffRequestDetailsScreen extends StatefulWidget {
  final MaintenanceRequest request;
  final int staffId;
  final VoidCallback onRequestUpdated;

  const StaffRequestDetailsScreen({
    super.key,
    required this.request,
    required this.staffId,
    required this.onRequestUpdated,
  });

  @override
  State<StaffRequestDetailsScreen> createState() =>
      _StaffRequestDetailsScreenState();
}

class _StaffRequestDetailsScreenState extends State<StaffRequestDetailsScreen> {
  final _notesController = TextEditingController();
  String _selectedStatus = '';
  bool _hasChanges = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status;
    _notesController.text = widget.request.progressNotes ?? '';

    // Listen for changes
    _notesController.addListener(() {
      setState(() {
        _hasChanges = true;
      });
    });
  }

  Future<void> _updateRequest() async {
    if (_selectedStatus == widget.request.status &&
        _notesController.text.trim() == (widget.request.progressNotes ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final updatedRequest = widget.request.copyWith(
        status: _selectedStatus,
        progressNotes: _notesController.text.trim(),
        completedAt: _selectedStatus == 'Completed' ? DateTime.now() : null,
      );

      await SupabaseService().updateRequest(
        widget.request.id!,
        updatedRequest.toMap(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedStatus == 'Completed'
                      ? 'Task marked as completed! 🎉'
                      : 'Task updated successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onRequestUpdated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      default:
        return Colors.grey;
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.hourglass_empty;
      case 'assigned':
        return Icons.assignment_turned_in;
      default:
        return Icons.pending;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentChatScreen(
                    studentId: widget.request.studentId,
                    staffId: widget.staffId.toString(),
                  ),
                ),
              );
            },
            tooltip: 'Message Student',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.request.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(widget.request.status),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(widget.request.status),
                    color: _getStatusColor(widget.request.status),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.request.status,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.request.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.request.status == 'Completed')
                    const Icon(Icons.verified, color: Colors.green, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Request Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.request.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(
                              widget.request.urgencyLevel,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high,
                                size: 16,
                                color: _getUrgencyColor(
                                  widget.request.urgencyLevel,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.request.urgencyLevel,
                                style: TextStyle(
                                  color: _getUrgencyColor(
                                    widget.request.urgencyLevel,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.person,
                      'Student',
                      widget.request.studentName,
                    ),
                    _buildInfoRow(
                      Icons.room,
                      'Room',
                      widget.request.roomNumber,
                    ),
                    _buildInfoRow(
                      Icons.category,
                      'Category',
                      widget.request.problemCategory,
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Submitted',
                      DateFormat(
                        'MMM d, y - h:mm a',
                      ).format(widget.request.createdAt),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.request.description,
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Update Status Section with Visual Feedback
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.update, color: AppConstants.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Update Task Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visual Status Selector (3 cards)
                    Column(
                      children: [
                        _buildStatusCard(
                          'Assigned',
                          'Task is assigned but not started yet',
                          Icons.assignment_turned_in,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusCard(
                          'In Progress',
                          'Currently working on this task',
                          Icons.hourglass_empty,
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusCard(
                          'Completed',
                          'Task is finished and resolved',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Progress Notes
                    const Text(
                      'Progress Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Add notes about your progress, issues found, or solutions applied...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    // Show previous notes if any
                    if (widget.request.progressNotes != null &&
                        widget.request.progressNotes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Previous Notes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.request.progressNotes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Update Button with Visual Feedback
            ElevatedButton(
              onPressed: _isUpdating ? null : _updateRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(_selectedStatus),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getStatusIcon(_selectedStatus)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedStatus == widget.request.status
                              ? 'Save Changes'
                              : 'Update to "$_selectedStatus"',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String status,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedStatus == status;
    final isCurrent = widget.request.status == status;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _hasChanges = true;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? color : Colors.grey[800],
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
