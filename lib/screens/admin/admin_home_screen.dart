import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../models/request.dart';
import 'admin_request_details_screen.dart';
import 'admin_reports_screen.dart';
import 'enhanced_staff_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<List<MaintenanceRequest>> _allRequests;
  int _selectedIndex = 0;
  String _selectedFilter = 'All';

  // Clean Professional Admin Color Scheme - White & Blue
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color veryLightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color inProgressBlue = Color(0xFF2196F3);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _allRequests = SupabaseService().getAllRequests();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _openRequestDetails(MaintenanceRequest request) {
    // Check if task is completed and show warning
    if (request.status == 'Completed') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: warningOrange),
              ),
              const SizedBox(width: 12),
              const Text(
                'Completed Task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            'This task has been marked as completed. Assignment changes are not allowed for completed tasks.',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Open details (assignment controls will be disabled for completed tasks)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminRequestDetailsScreen(
                      request: request,
                      onRequestUpdated: _reload,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
      );
    } else {
      // Normal navigation for non-completed tasks
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdminRequestDetailsScreen(
            request: request,
            onRequestUpdated: _reload,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Portal',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Maintenance Management System',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: veryLightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
            ),
            child: IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: primaryBlue),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildRequestsList()
          : _buildDashboardOptions(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: primaryBlue,
          unselectedItemColor: textSecondary,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return FutureBuilder<List<MaintenanceRequest>>(
      future: _allRequests,
      builder: (_, snap) {
        if (!snap.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
                const SizedBox(height: 16),
                const Text(
                  'Loading requests...',
                  style: TextStyle(color: textSecondary, fontSize: 15),
                ),
              ],
            ),
          );
        }

        var items = snap.data!;

        // Apply filters
        if (_selectedFilter == 'Pending') {
          items = items
              .where(
                (req) =>
                    req.assignedStaff == null ||
                    (req.status != 'In Progress' && req.status != 'Completed'),
              )
              .toList();
        } else if (_selectedFilter == 'In Progress') {
          items = items.where((req) => req.status == 'In Progress').toList();
        } else if (_selectedFilter == 'Completed') {
          items = items.where((req) => req.status == 'Completed').toList();
        } else if (_selectedFilter == 'Assigned') {
          items = items
              .where(
                (req) => req.assignedStaff != null && req.status != 'Completed',
              )
              .toList();
        } else if (_selectedFilter != 'All') {
          // Urgency filters (High, Medium, Low)
          items = items
              .where((req) => req.urgencyLevel == _selectedFilter)
              .toList();
        }

        return Column(
          children: [
            _buildFilterButtons(),
            _buildStatsBar(snap.data!),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: veryLightBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: primaryBlue.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No requests found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: primaryBlue,
                      backgroundColor: cardWhite,
                      onRefresh: () async => _reload(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final req = items[i];
                          return _buildRequestCard(req);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(MaintenanceRequest req) {
    final urgencyColor = _getUrgencyColor(req.urgencyLevel);
    final isAssigned = req.assignedStaff != null;
    final status = req.status ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final isCompleted = status == 'Completed';
    final isInProgress = status == 'In Progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? successGreen.withOpacity(0.3)
              : isInProgress
              ? inProgressBlue.withOpacity(0.3)
              : borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRequestDetails(req),
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryBlue.withOpacity(0.08),
          highlightColor: primaryBlue.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? textSecondary : textPrimary,
                          letterSpacing: -0.3,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: urgencyColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: urgencyColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            req.urgencyLevel.toUpperCase(),
                            style: TextStyle(
                              color: urgencyColor,
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
                const SizedBox(height: 14),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Assignment Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAssigned
                        ? successGreen.withOpacity(0.08)
                        : warningOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAssigned
                          ? successGreen.withOpacity(0.2)
                          : warningOrange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAssigned
                            ? Icons.person_rounded
                            : Icons.schedule_rounded,
                        size: 20,
                        color: isAssigned ? successGreen : warningOrange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAssigned
                              ? "Assigned to: ${req.assignedStaff}"
                              : "Awaiting assignment",
                          style: TextStyle(
                            color: isAssigned ? successGreen : warningOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: successGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Icon(
                        isCompleted
                            ? Icons.lock_outline_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: textSecondary.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),

                // Show progress notes if available
                if (req.progressNotes != null && req.progressNotes!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: veryLightBlue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded, size: 16, color: primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req.progressNotes!,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return dangerRed;
      case 'medium':
        return warningOrange;
      case 'low':
        return const Color(0xFF2196F3);
      default:
        return textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successGreen;
      case 'in progress':
        return inProgressBlue;
      case 'pending':
      default:
        return warningOrange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'in progress':
        return Icons.sync_rounded;
      case 'pending':
      default:
        return Icons.pending_rounded;
    }
  }

  Widget _buildStatsBar(List<MaintenanceRequest> allItems) {
    final total = allItems.length;
    final pending = allItems
        .where(
          (r) =>
              r.assignedStaff == null ||
              (r.status != 'In Progress' && r.status != 'Completed'),
        )
        .length;
    final inProgress = allItems.where((r) => r.status == 'In Progress').length;
    final completed = allItems.where((r) => r.status == 'Completed').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total.toString(), Icons.receipt_long_rounded),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('Pending', pending.toString(), Icons.schedule_rounded),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            'In Progress',
            inProgress.toString(),
            Icons.sync_rounded,
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            'Completed',
            completed.toString(),
            Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    const filters = [
      'All',
      'Pending',
      'In Progress',
      'Completed',
      'High',
      'Medium',
      'Low',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : cardWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? primaryBlue : borderColor,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control Panel',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your maintenance operations efficiently',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 28),
          _buildDashboardCard(
            'View All Requests',
            'Manage and assign maintenance requests',
            Icons.assignment_rounded,
            primaryBlue,
            () => setState(() => _selectedIndex = 0),
          ),
          const SizedBox(height: 14),
          _buildDashboardCard(
            'Staff Management',
            'View and manage staff assignments',
            Icons.people_rounded,
            const Color(0xFF7C3AED),
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EnhancedStaffManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildDashboardCard(
            'Reports & Analytics',
            'View maintenance statistics and reports',
            Icons.analytics_rounded,
            successGreen,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildDashboardCard(
            'Settings',
            'Configure app settings and preferences',
            Icons.settings_rounded,
            warningOrange,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Settings coming soon!'),
                  backgroundColor: textPrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.08),
          highlightColor: color.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
