import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // fallback/browser load
import '../../models/exam_model.dart';
import '../../services/api_service.dart';
import '../../constants/api_endpoints.dart';
import '../../constants/app_colors.dart';

class ResultFeedbackScreen extends StatefulWidget {
  final ExamModel exam;

  const ResultFeedbackScreen({super.key, required this.exam});

  @override
  State<ResultFeedbackScreen> createState() => _ResultFeedbackScreenState();
}

class _ResultFeedbackScreenState extends State<ResultFeedbackScreen> {
  bool _loading = true;
  Map<String, dynamic>? _sessionData;
  List<dynamic> _answers = [];

  @override
  void initState() {
    super.initState();
    _fetchResultDetails();
  }

  Future<void> _fetchResultDetails() async {
    try {
      final res = await ApiService.get('${ApiEndpoints.examResultDetails}?student_exam_id=${widget.exam.id}');
      if (res['success'] == true) {
        if (!mounted) return;
        setState(() {
          _sessionData = res['session'] as Map<String, dynamic>;
          _answers = res['answers'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load details: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final score = double.parse(_sessionData?['score']?.toString() ?? '0.00');
    final totalMarks = double.parse(_sessionData?['total_marks']?.toString() ?? '10.00');
    final passingMarks = double.parse(_sessionData?['passing_marks']?.toString() ?? '4.00');
    final isPassed = score >= passingMarks;
    final percentage = (score / totalMarks) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scorecard: ${widget.exam.title}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result Overview Card
            Card(
              color: isPassed ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isPassed ? AppColors.accent : AppColors.error,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isPassed ? Icons.emoji_events_outlined : Icons.sentiment_dissatisfied_outlined,
                      size: 64,
                      color: isPassed ? AppColors.accent : AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPassed ? 'CONGRATULATIONS!' : 'KEEP LEARNING!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isPassed ? AppColors.accent : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You scored $score out of $totalMarks points.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score Percentage: ${percentage.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPassed ? AppColors.accent : AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPassed ? 'PASSED' : 'FAILED',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Download PDF Card
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                // Open browser print page
                final url = '${ApiEndpoints.downloadReport}?student_exam_id=${widget.exam.id}';
                // Try launching the URL
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download Result PDF / Certificate'),
            ),
            const SizedBox(height: 32),

            const Text(
              'Questions Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Question Breakdown List
            ...List.generate(_answers.length, (idx) {
              final ans = _answers[idx];
              final isCorrect = ans['is_correct'].toString() == '1' || ans['is_correct'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${idx + 1}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isCorrect ? 'Correct' : 'Incorrect',
                              style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ans['question_text'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your Choice: ${ans['selected_option_text'] ?? 'Unanswered'}',
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marks Obtained: ${ans['marks_obtained']} / ${ans['q_marks']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
