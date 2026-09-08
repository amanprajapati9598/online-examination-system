import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exam_model.dart';
import '../../providers/student_provider.dart';
import 'exam_session_screen.dart';

class ExamInstructionsScreen extends StatelessWidget {
  final ExamModel exam;

  const ExamInstructionsScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Instructions: ${exam.title}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Card
            if (exam.antiCheatingEnabled)
              Card(
                color: Colors.red.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anti-Cheating Protection Active',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '1. Full-screen Mode is enforced. Do not exit full-screen.\n'
                              '2. Changing tabs, minimizing the app, or answering incoming calls will log a warning.\n'
                              '3. Reaching 3 violations triggers immediate auto-submission.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Exam Info Summary
            const Text('Exam Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.timer_outlined, 'Duration', '${exam.durationMinutes} Minutes'),
            _buildInfoRow(Icons.grade_outlined, 'Total Marks', '${exam.totalMarks} Points'),
            _buildInfoRow(Icons.check_circle_outline, 'Passing Marks', '${exam.passingMarks} Points'),
            if (exam.negativeMarkingFactor > 0)
              _buildInfoRow(Icons.remove_circle_outline, 'Negative Marking', '-${(exam.negativeMarkingFactor * 100).toInt()}% per incorrect answer'),

            const SizedBox(height: 32),

            // General Instructions
            const Text('General Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '• Ensure you have a stable network connection before starting.\n'
              '• Read each question carefully before submitting an answer.\n'
              '• Your answers are saved automatically as you work. In case of power failure, relaunch the app to continue.\n'
              '• Once you click "Start Exam", the countdown timer will begin and cannot be paused.',
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey),
            ),

            const SizedBox(height: 48),

            // Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: studentProvider.isLoading
                  ? null
                  : () async {
                      try {
                        await studentProvider.startExam(exam.id);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExamSessionScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: studentProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Start Examination', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
