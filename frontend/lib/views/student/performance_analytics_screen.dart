import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/student_provider.dart';
import '../../constants/app_colors.dart';

class PerformanceAnalyticsScreen extends StatefulWidget {
  const PerformanceAnalyticsScreen({super.key});

  @override
  State<PerformanceAnalyticsScreen> createState() => _PerformanceAnalyticsScreenState();
}

class _PerformanceAnalyticsScreenState extends State<PerformanceAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudentAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<StudentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
      ),
      body: sp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary cards
                  _buildSummarySection(sp),
                  const SizedBox(height: 30),

                  // Score progression chart
                  const Text('Score Progression', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildChartSection(sp),
                  const SizedBox(height: 35),

                  // Leaderboard
                  const Text('Leaderboard Rankings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildLeaderboardSection(sp),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection(StudentProvider sp) {
    final sum = sp.analyticsSummary ?? {};
    final total = sum['total_exams'] ?? 0;
    final passed = sum['passed_exams'] ?? 0;
    final failed = sum['failed_exams'] ?? 0;
    final avg = sum['average_score'] ?? 0.00;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Exams Taken', total.toString(), Icons.assignment_outlined, AppColors.primary),
        _buildStatCard('Passed', passed.toString(), Icons.check_circle_outline, AppColors.accent),
        _buildStatCard('Failed', failed.toString(), Icons.cancel_outlined, AppColors.error),
        _buildStatCard('Average Grade', avg.toString(), Icons.insights, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(StudentProvider sp) {
    final prog = sp.analyticsProgression;
    if (prog.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('Not enough data to map progress.')),
        ),
      );
    }

    // Convert scores to FlSpot
    List<FlSpot> spots = [];
    for (int i = 0; i < prog.length; i++) {
      spots.add(FlSpot(i.toDouble(), double.parse(prog[i]['score'].toString())));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 4,
                  color: AppColors.primary,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection(StudentProvider sp) {
    final lb = sp.leaderboard;
    if (lb.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No entries on the leaderboard.')),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lb.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = lb[index];
          final isTopThree = index < 3;
          final medalColor = [Colors.amber, Colors.grey, Colors.brown];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isTopThree ? medalColor[index] : Colors.grey.shade300,
              foregroundColor: isTopThree ? Colors.white : Colors.black87,
              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Exams attempted: ${entry.examsTaken}'),
            trailing: Text(
              '${entry.totalPoints} pts',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
