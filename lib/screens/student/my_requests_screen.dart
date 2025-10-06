import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/database_service.dart';
import '../../models/request.dart';

class MyRequestsScreen extends StatefulWidget {
  final String studentId;
  const MyRequestsScreen({super.key, required this.studentId});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late Future<List<MaintenanceRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService().getRequestsByStudentId(widget.studentId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = SupabaseService().getRequestsByStudentId(widget.studentId);
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "in progress":
        return Colors.blue;
      case "completed":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _urgencyIcon(String urgency) {
    switch (urgency.toLowerCase()) {
      case "high":
        return Icons.priority_high;
      case "medium":
        return Icons.warning_amber_rounded;
      case "low":
        return Icons.low_priority;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Requests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        elevation: 2,
      ),
      body: FutureBuilder<List<MaintenanceRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No requests yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Category + Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.problemCategory,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(r.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                r.status,
                                style: TextStyle(
                                  color: _statusColor(r.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Description
                        Text(
                          r.description,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),

                        const SizedBox(height: 10),

                        // Urgency indicator
                        Row(
                          children: [
                            Icon(
                              _urgencyIcon(r.urgencyLevel),
                              color: _statusColor(r.status),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Urgency: ${r.urgencyLevel}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
