import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/user.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  late Future<List<User>> _staffList;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _staffList = DatabaseService.instance.getAllStaff();
    });
  }

  void _showAddStaffDialog() {
    final _formKey = GlobalKey<FormState>();
    final _fullNameController = TextEditingController();
    final _staffIdController = TextEditingController();
    final _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter full name'
                    : null,
              ),
              TextFormField(
                controller: _staffIdController,
                decoration: const InputDecoration(labelText: 'Staff ID'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter staff ID'
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
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
              if (!_formKey.currentState!.validate()) return;

              final staff = User(
                username: _staffIdController.text.trim(),
                password: _passwordController.text.trim(),
                fullName: _fullNameController.text.trim(),
                studentId: _staffIdController.text.trim(),
                email: '${_staffIdController.text.trim()}@dormfix.com',
                userType: UserType.staff,
              );

              try {
                await DatabaseService.instance.addStaff(staff);
                Navigator.pop(context);
                _reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
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
            child: ElevatedButton(
              onPressed: _showAddStaffDialog,
              child: const Text('Add Staff'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _staffList,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final staffList = snapshot.data!;
                if (staffList.isEmpty)
                  return const Center(child: Text('No staff members found'));
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
                        title: Text(staff.fullName),
                        subtitle: Text(
                          'Assigned Requests: ${staff.assignedRequestsCount}',
                        ),
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
