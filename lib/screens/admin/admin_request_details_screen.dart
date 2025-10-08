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
  int? _selectedStaffId;
  Student? _reporter;
  List<Staff> _allStaff = [];
  bool _isLoading = true;

  // Light Blue Professional Theme
  static const Color primaryLight = Color(0xFFF8FAFC);
  static const Color secondaryLight = Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color skyBlue = Color(0xFF60A5FA);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x0F000000);

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.request.assignedStaff;
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
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  bool _isRequestCompleted() {
    return widget.request.status.toLowerCase() == 'completed';
  }

  Future<void> _assignOrChangeStaff() async {
    if (_isRequestCompleted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Cannot modify completed requests")),
            ],
          ),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select a staff member"),
          backgroundColor: warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      final oldStaff = widget.request.assignedStaff;

      final updatedRequest = widget.request.copyWith(
        assignedStaff: _selectedStaffId,
        status: "Assigned",
      );

      await SupabaseService().updateRequest(
        widget.request.id!,
        updatedRequest.toMap(),
      );

      if (!mounted) return;

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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text("Task assigned to $newStaffName"),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            content: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Reassigned: $oldStaffName → $newStaffName"),
                ),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return dangerColor;
      case 'medium':
        return warningColor;
      case 'low':
        return primaryBlue;
      default:
        return textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: primaryLight,
        appBar: AppBar(
          backgroundColor: secondaryLight,
          elevation: 0,
          title: const Text(
            "Request Details",
            style: TextStyle(color: textPrimary),
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
              const SizedBox(height: 16),
              const Text(
                'Loading request details...',
                style: TextStyle(color: textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final request = widget.request;

    return Scaffold(
      backgroundColor: primaryLight,
      appBar: AppBar(
        backgroundColor: secondaryLight,
        elevation: 0,
        title: const Text(
          "Request Details",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(request),
            const SizedBox(height: 16),
            if (_isRequestCompleted()) _buildCompletedBanner(),
            if (_isRequestCompleted()) const SizedBox(height: 16),
            _buildQuickStats(request),
            const SizedBox(height: 16),
            _buildRequestDetailsCard(request),
            const SizedBox(height: 16),
            if (_reporter != null) _buildStudentInfoCard(),
            if (_reporter != null) const SizedBox(height: 16),
            if (request.photoPath != null && request.photoPath!.isNotEmpty)
              _buildPhotoCard(request),
            if (request.photoPath != null && request.photoPath!.isNotEmpty)
              const SizedBox(height: 16),
            _buildStaffAssignmentCard(request),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successColor.withOpacity(0.1),
            successColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: successColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This request has been marked as completed and is now locked.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, color: successColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(MaintenanceRequest request) {
    final urgencyColor = _getUrgencyColor(request.urgencyLevel);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Request Information',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: urgencyColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.urgencyLevel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            request.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(MaintenanceRequest request) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            Icons.category_rounded,
            'Category',
            request.problemCategory,
            lightBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            Icons.door_front_door_rounded,
            'Room',
            request.roomNumber,
            const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            Icons.info_rounded,
            'Status',
            request.status,
            _getStatusColor(request.status),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successColor;
      case 'in progress':
        return lightBlue;
      case 'assigned':
        return warningColor;
      default:
        return textSecondary;
    }
  }

  Widget _buildRequestDetailsCard(MaintenanceRequest request) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: lightBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Request Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Created',
            DateFormat('MMM dd, yyyy • HH:mm').format(request.createdAt),
          ),
          const SizedBox(height: 18),
          const Divider(color: borderColor, height: 1),
          const SizedBox(height: 18),
          const Text(
            'Description',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              request.description,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Student Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.badge_rounded, 'Name', _reporter!.name),
          const SizedBox(height: 14),
          _buildDetailRow(Icons.fingerprint_rounded, 'ID', _reporter!.id),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.door_front_door_rounded,
            'Room',
            _reporter!.roomNumber,
          ),
          const SizedBox(height: 20),
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
              icon: const Icon(Icons.message_rounded, size: 20),
              label: const Text(
                "Message Student",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(MaintenanceRequest request) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Attached Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              request.photoPath!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: dangerColor.withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Image failed to load",
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAssignmentCard(MaintenanceRequest request) {
    final isCompleted = _isRequestCompleted();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isCompleted ? textSecondary : successColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted ? Icons.lock_rounded : Icons.engineering_rounded,
                  color: isCompleted ? textSecondary : successColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCompleted
                      ? 'Staff Assignment (Locked)'
                      : 'Staff Assignment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? textSecondary : textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_allStaff.isNotEmpty)
            Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted
                      ? borderColor.withOpacity(0.3)
                      : primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: DropdownButtonFormField<int>(
                  value:
                      _selectedStaffId != null &&
                          _allStaff.any((staff) => staff.id == _selectedStaffId)
                      ? _selectedStaffId
                      : null,
                  items: _allStaff
                      .map(
                        (staff) => DropdownMenuItem<int>(
                          value: staff.id,
                          enabled: !isCompleted,
                          child: Text(
                            "${staff.name} (${staff.availability})",
                            style: TextStyle(
                              color: isCompleted ? textSecondary : textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  decoration: InputDecoration(
                    labelText: isCompleted
                        ? "Staff Assignment Locked"
                        : "Select Staff Member",
                    labelStyle: TextStyle(
                      color: isCompleted ? textSecondary : textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      isCompleted
                          ? Icons.lock_rounded
                          : Icons.person_search_rounded,
                      color: isCompleted ? textSecondary : primaryBlue,
                    ),
                  ),
                  dropdownColor: secondaryLight,
                  style: TextStyle(
                    color: isCompleted ? textSecondary : textPrimary,
                  ),
                  onChanged: isCompleted
                      ? null
                      : (value) => setState(() => _selectedStaffId = value),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dangerColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: dangerColor, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "No staff members available",
                      style: TextStyle(color: dangerColor),
                    ),
                  ),
                ],
              ),
            ),
          if (isCompleted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: successColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded, color: successColor, size: 18),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "This request is completed and cannot be modified",
                      style: TextStyle(
                        color: successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCompleted ? null : _assignOrChangeStaff,
              icon: Icon(
                isCompleted ? Icons.lock_rounded : Icons.check_circle_rounded,
                size: 20,
              ),
              label: Text(
                isCompleted ? "Request Locked" : "Assign/Change Staff",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? textSecondary : successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: textSecondary.withOpacity(0.5),
                disabledForegroundColor: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
