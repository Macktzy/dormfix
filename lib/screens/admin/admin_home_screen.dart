import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../models/request.dart';
import 'admin_request_details_screen.dart';
import 'admin_reports_screen.dart';
import 'staff_management_screen.dart'; // adjust the filename

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<List<MaintenanceRequest>> _allRequests;
  int _selectedIndex = 0;
  String _selectedFilter = 'All';

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminRequestDetailsScreen(
          request: request,
          onRequestUpdated: _reload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildRequestsList()
          : _buildDashboardOptions(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return FutureBuilder<List<MaintenanceRequest>>(
      future: _allRequests,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snap.data!;

        // ✅ Apply filters
        if (_selectedFilter == 'Assigned') {
          items = items.where((req) => req.assignedStaff != null).toList();
        } else if (_selectedFilter != 'All') {
          items = items
              .where((req) => req.urgencyLevel == _selectedFilter)
              .toList();
        }

        return Column(
          children: [
            _buildFilterButtons(),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No requests found',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final req = items[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(req.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Urgency: ${req.urgencyLevel}"),
                                const SizedBox(height: 4),
                                if (req.assignedStaff != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text("Assigned to: ${req.assignedStaff}"),
                                    ],
                                  )
                                else
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.error,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 4),
                                      Text("Unassigned"),
                                    ],
                                  ),
                              ],
                            ),
                            onTap: () => _openRequestDetails(req),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterButtons() {
    // ✅ Added "Assigned" filter
    const filters = ['All', 'High', 'Medium', 'Low', 'Assigned'];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        children: filters.map((filter) {
          return ChoiceChip(
            label: Text(filter),
            selected: _selectedFilter == filter,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboardOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dashboard Options',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDashboardCard(
            'View All Requests',
            'Manage and assign maintenance requests',
            Icons.list_alt,
            () => setState(() => _selectedIndex = 0),
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            'Staff Management',
            'View and manage staff assignments',
            Icons.people,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StaffManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            'Reports & Analytics',
            'View maintenance statistics and reports',
            Icons.analytics,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            'Settings',
            'Configure app settings and preferences',
            Icons.settings,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
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
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
