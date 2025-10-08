import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/staff.dart';
import '../../models/request.dart';
import 'admin_staff_chat_screen.dart';

class EnhancedStaffManagementScreen extends StatefulWidget {
  const EnhancedStaffManagementScreen({super.key});

  @override
  State<EnhancedStaffManagementScreen> createState() =>
      _EnhancedStaffManagementScreenState();
}

class _EnhancedStaffManagementScreenState
    extends State<EnhancedStaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Staff>> _staffList;
  late Future<List<MaintenanceRequest>> _allRequests;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _staffList = SupabaseService().getAllStaff();
      _allRequests = SupabaseService().getAllRequests();
    });
  }

  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final staffIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Add New Staff'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter full name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: staffIdController,
                  decoration: const InputDecoration(
                    labelText: 'Staff ID',
                    hintText: 'e.g., STAFF001',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter staff ID'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.account_circle),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter username'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter password'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                await SupabaseService().addStaff(
                  username: usernameController.text.trim(),
                  password: passwordController.text.trim(),
                  fullName: fullNameController.text.trim(),
                  staffId: staffIdController.text.trim(),
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                _reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding staff: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }

  void _openChat(Staff staff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminStaffChatScreen(staffId: staff.id!, adminId: 'admin'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Staff', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Available', icon: Icon(Icons.check, size: 20)),
            Tab(text: 'Busy', icon: Icon(Icons.schedule, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search staff by name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStaffList(null),
                _buildStaffList('Available'),
                _buildStaffList('Busy'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStaffList(String? filter) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_staffList, _allRequests]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _reload, child: const Text('Retry')),
              ],
            ),
          );
        }

        final staffList = snapshot.data![0] as List<Staff>;
        final allRequests = snapshot.data![1] as List<MaintenanceRequest>;

        var filteredStaff = staffList.where((staff) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              staff.name.toLowerCase().contains(_searchQuery) ||
              staff.staffId.toLowerCase().contains(_searchQuery);

          final matchesFilter = filter == null || staff.availability == filter;

          return matchesSearch && matchesFilter;
        }).toList();

        if (filteredStaff.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No staff found matching "$_searchQuery"'
                      : 'No ${filter ?? 'staff'} members found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredStaff.length,
            itemBuilder: (context, index) {
              final staff = filteredStaff[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {}, // details removed for brevity
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue[600],
                          child: Text(
                            staff.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ✅ make this whole area flexible
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Staff ID: ${staff.staffId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // ✅ FIXED OVERFLOW: use Wrap instead of Row
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.assignment,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${staff.assignedRequestsCount} assigned',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.priority_high,
                                        size: 14,
                                        color: Colors.red[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${staff.highUrgencyCount} high priority',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: staff.availability == 'Available'
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                staff.availability,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              onPressed: () => _openChat(staff),
                              icon: const Icon(Icons.message),
                              color: Colors.blue[600],
                              tooltip: 'Message Staff',
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
