import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exam_model.dart';
import '../../providers/teacher_provider.dart';
import '../../constants/api_endpoints.dart';
import '../../constants/app_colors.dart';

class ExamResultsScreen extends StatefulWidget {
  final ExamModel exam;

  const ExamResultsScreen({super.key, required this.exam});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load specific student sessions list
      Provider.of<TeacherProvider>(context, listen: false).fetchActiveExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TeacherProvider>(context);

    // Filter results for this exam only
    final results = tp.activeExams.where((res) => res.examTitle == widget.exam.title).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Results: ${widget.exam.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Export CSV',
            onPressed: () {
              final url = '${ApiEndpoints.exportCSV}?exam_id=${widget.exam.id}';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          )
        ],
      ),
      body: tp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.query_stats, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No student results recorded for this exam yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final res = results[index];
                    final scorePct = (res.score / widget.exam.totalMarks) * 100;
                    final pass = res.score >= widget.exam.passingMarks;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.studentName ?? 'Student',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(res.studentEmail ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pass ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${res.score} / ${widget.exam.totalMarks}',
                                    style: TextStyle(
                                      color: pass ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailItem('Percentage', '${scorePct.toStringAsFixed(1)}%'),
                                _buildDetailItem('Tab Switches', res.tabSwitchesCount.toString(), isAlert: res.tabSwitchesCount > 0),
                                _buildDetailItem('Fullscreen Exits', res.fullscreenExitsCount.toString(), isAlert: res.fullscreenExitsCount > 0),
                                _buildDetailItem('Auto Submit', res.autoSubmitted ? 'Yes' : 'No', isAlert: res.autoSubmitted),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isAlert = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isAlert ? Colors.redAccent : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
