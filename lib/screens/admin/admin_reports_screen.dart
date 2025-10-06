import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_service.dart';
import '../../models/request.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late Future<List<MaintenanceRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = SupabaseService().getAllRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports & Analytics")),
      body: FutureBuilder<List<MaintenanceRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;

          // 📊 Assigned vs Unassigned
          final assignedCount = requests
              .where((r) => r.assignedStaff != null)
              .length;
          final unassignedCount = requests.length - assignedCount;

          // 📊 Urgency Distribution
          final highCount = requests
              .where((r) => r.urgencyLevel == "High")
              .length;
          final mediumCount = requests
              .where((r) => r.urgencyLevel == "Medium")
              .length;
          final lowCount = requests
              .where((r) => r.urgencyLevel == "Low")
              .length;

          // 📊 Requests Over Time (group by date)
          final Map<String, int> requestsPerDay = {};
          for (var r in requests) {
            final date = DateFormat('MM-dd').format(r.createdAt);
            requestsPerDay[date] = (requestsPerDay[date] ?? 0) + 1;
          }

          final sortedDates = requestsPerDay.keys.toList()..sort();
          final spots = sortedDates.asMap().entries.map((entry) {
            int index = entry.key;
            String date = entry.value;
            return FlSpot(index.toDouble(), requestsPerDay[date]!.toDouble());
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("Assigned vs Unassigned"),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: assignedCount.toDouble(),
                          title: "Assigned",
                          color: Colors.green,
                        ),
                        PieChartSectionData(
                          value: unassignedCount.toDouble(),
                          title: "Unassigned",
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _buildSectionTitle("Urgency Distribution"),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: highCount.toDouble(),
                          title: "High",
                          color: Colors.red,
                        ),
                        PieChartSectionData(
                          value: mediumCount.toDouble(),
                          title: "Medium",
                          color: Colors.orange,
                        ),
                        PieChartSectionData(
                          value: lowCount.toDouble(),
                          title: "Low",
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _buildSectionTitle("Requests Over Time"),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= sortedDates.length)
                                return const Text('');
                              return Text(
                                sortedDates[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
