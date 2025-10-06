import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/staff.dart'; // Changed from user.dart to staff.dart

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  late Future<List<Staff>> _staffList; // Changed from List<User> to List<Staff>

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _staffList = SupabaseService().getAllStaff();
    });
  }

  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter full name'
                    : null,
              ),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter username'
                    : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter password'
                    : null,
              ),
            ],
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
            child: const Text('Add Staff'),
          ),
        ],
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddStaffDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Staff>>(
              future: _staffList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No staff members found'));
                }

                final staffList = snapshot.data!;
                return ListView.builder(
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[600],
                          child: Text(
                            staff.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          staff.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Username: ${staff.name}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
