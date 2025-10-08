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
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _requestsFuture = SupabaseService().getAllRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
                Icons.analytics_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'System Overview',
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
      ),
      body: FutureBuilder<List<MaintenanceRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading analytics...',
                    style: TextStyle(color: textSecondary, fontSize: 15),
                  ),
                ],
              ),
            );
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
                // Summary Cards
                _buildSummaryCards(
                  requests.length,
                  assignedCount,
                  unassignedCount,
                ),
                const SizedBox(height: 20),

                // Assigned vs Unassigned Chart
                _buildChartCard(
                  title: "Assignment Status",
                  subtitle: "Distribution of assigned and unassigned requests",
                  icon: Icons.assignment_turned_in_rounded,
                  child: SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: assignedCount.toDouble(),
                            title:
                                "${((assignedCount / requests.length) * 100).toStringAsFixed(0)}%",
                            color: successGreen,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: unassignedCount.toDouble(),
                            title:
                                "${((unassignedCount / requests.length) * 100).toStringAsFixed(0)}%",
                            color: dangerRed,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  legend: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("Assigned", successGreen, assignedCount),
                      const SizedBox(width: 24),
                      _buildLegendItem(
                        "Unassigned",
                        dangerRed,
                        unassignedCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Urgency Distribution Chart
                _buildChartCard(
                  title: "Urgency Distribution",
                  subtitle: "Breakdown by priority levels",
                  icon: Icons.priority_high_rounded,
                  child: SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: highCount.toDouble(),
                            title:
                                "${((highCount / requests.length) * 100).toStringAsFixed(0)}%",
                            color: dangerRed,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: mediumCount.toDouble(),
                            title:
                                "${((mediumCount / requests.length) * 100).toStringAsFixed(0)}%",
                            color: warningOrange,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: lowCount.toDouble(),
                            title:
                                "${((lowCount / requests.length) * 100).toStringAsFixed(0)}%",
                            color: primaryBlue,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  legend: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("High", dangerRed, highCount),
                      const SizedBox(width: 16),
                      _buildLegendItem("Medium", warningOrange, mediumCount),
                      const SizedBox(width: 16),
                      _buildLegendItem("Low", primaryBlue, lowCount),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Requests Over Time Chart
                _buildChartCard(
                  title: "Requests Over Time",
                  subtitle: "Daily request trends",
                  icon: Icons.show_chart_rounded,
                  child: SizedBox(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(color: borderColor, strokeWidth: 1);
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= sortedDates.length)
                                    return const Text('');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      sortedDates[value.toInt()],
                                      style: const TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: borderColor, width: 1),
                              left: BorderSide(color: borderColor, width: 1),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [primaryBlue, lightBlue],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: cardWhite,
                                    strokeWidth: 2,
                                    strokeColor: primaryBlue,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    primaryBlue.withOpacity(0.2),
                                    lightBlue.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          minY: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int total, int assigned, int unassigned) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            "Total Requests",
            total.toString(),
            Icons.receipt_long_rounded,
            primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            "Assigned",
            assigned.toString(),
            Icons.check_circle_outline_rounded,
            successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            "Pending",
            unassigned.toString(),
            Icons.schedule_rounded,
            warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? legend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
          if (legend != null) ...[const SizedBox(height: 16), legend],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "$label ($count)",
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
