import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import 'submit_request_screen.dart';
import 'my_requests_screen.dart';
import 'student_chat_screen.dart';
import '../../services/database_service.dart';
import '../../models/request.dart';

class StudentHomeScreen extends StatefulWidget {
  final String studentId;
  final String fullName;

  const StudentHomeScreen({
    super.key,
    required this.studentId,
    required this.fullName,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<MaintenanceRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final requests = await DatabaseService.instance.getRequestsByStudentId(
      widget.studentId,
    );
    setState(() {
      _requests = requests;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Hello, ${widget.fullName}'),
                subtitle: Text('Student ID: ${widget.studentId}'),
                leading: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Submit Maintenance Request'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubmitRequestScreen(
                        studentId: widget.studentId,
                        studentName: widget.fullName,
                      ),
                    ),
                  ).then((_) => _loadRequests());
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text('My Requests'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyRequestsScreen(studentId: widget.studentId),
                    ),
                  ).then((_) => _loadRequests());
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _requests.isEmpty
                  ? const Center(child: Text("No assigned staff yet."))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final req = _requests[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(req.title),
                            subtitle: Text("Status: ${req.status}"),
                            trailing: req.assignedStaff != null
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.message,
                                      color: Colors.blue,
                                    ),
                                    tooltip: "Message Assigned Staff",
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentChatScreen(
                                            studentId: widget.studentId,
                                            staffId: req.assignedStaff!
                                                .toString(), // ✅ Convert int to String
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
