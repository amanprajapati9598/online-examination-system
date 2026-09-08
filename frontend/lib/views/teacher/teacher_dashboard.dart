import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/theme_provider.dart';
import 'exam_editor_screen.dart';
import 'questions_bank_screen.dart';
import 'exam_results_screen.dart';
import '../../models/exam_model.dart';
import '../../constants/app_colors.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = Provider.of<ExamProvider>(context, listen: false);
      final tp = Provider.of<TeacherProvider>(context, listen: false);
      ep.fetchExams();
      ep.fetchCourses();
      ep.fetchSubjects();
      tp.fetchTeacherStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final examProvider = Provider.of<ExamProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.assignment_ind, color: AppColors.primary),
            SizedBox(width: 8),
            Text('SmartExam - Examiner'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: examProvider.isLoading || teacherProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await examProvider.fetchExams();
                await teacherProvider.fetchTeacherStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Counters
                    _buildStatsRow(teacherProvider),
                    const SizedBox(height: 30),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Assessments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExamEditorScreen(), // New Exam
                              ),
                            ).then((_) => examProvider.fetchExams());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Exam'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Exams list
                    if (examProvider.exams.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No exams created yet. Tap "New Exam" to begin.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(examProvider.exams.length, (index) {
                        final exam = examProvider.exams[index];
                        return _buildExamRow(context, exam, examProvider);
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsRow(TeacherProvider tp) {
    final stats = tp.teacherStats ?? {};
    final exams = stats['exams'] ?? 0;
    final questions = stats['questions'] ?? 0;
    final submissions = stats['submissions'] ?? 0;

    return Row(
      children: [
        Expanded(child: _buildCounterCard('Created Exams', exams.toString(), Icons.assignment)),
        const SizedBox(width: 12),
        Expanded(child: _buildCounterCard('Questions Bank', questions.toString(), Icons.folder_open)),
        const SizedBox(width: 12),
        Expanded(child: _buildCounterCard('Submissions', submissions.toString(), Icons.fact_check_outlined)),
      ],
    );
  }

  Widget _buildCounterCard(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildExamRow(BuildContext context, ExamModel exam, ExamProvider ep) {
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
                  exam.subjectName ?? 'Subject',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: exam.isPublished ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    exam.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: exam.isPublished ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exam.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Duration: ${exam.durationMinutes} mins', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.quiz_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  // Model parses dynamic question counters
                  'Questions: ${exam.toJson()['question_count'] ?? 0}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  tooltip: 'Edit Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamEditorScreen(exam: exam),
                      ),
                    ).then((_) => ep.fetchExams());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.library_books_outlined, color: Colors.green),
                  tooltip: 'Questions Bank',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionsBankScreen(exam: exam),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: Colors.purple),
                  tooltip: 'Student Results',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamResultsScreen(exam: exam),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Exam',
                  onPressed: () => _confirmDelete(context, exam, ep),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext dashboardContext, ExamModel exam, ExamProvider ep) {
    showDialog(
      context: dashboardContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Exam'),
          content: Text('Are you sure you want to permanently delete "${exam.title}"?\nAll student scores and logs will be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ep.deleteExam(exam.id);
                  if (!dashboardContext.mounted) return;
                  ScaffoldMessenger.of(dashboardContext).showSnackBar(
                    const SnackBar(content: Text('Exam deleted successfully'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (!dashboardContext.mounted) return;
                  ScaffoldMessenger.of(dashboardContext).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
