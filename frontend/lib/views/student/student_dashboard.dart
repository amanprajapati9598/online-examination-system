import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/theme_provider.dart';
import 'qr_scanner_screen.dart';
import 'exam_instructions_screen.dart';
import 'result_feedback_screen.dart';
import 'performance_analytics_screen.dart';
import '../../models/exam_model.dart';
import '../../constants/app_colors.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = Provider.of<StudentProvider>(context, listen: false);
      sp.fetchAvailableExams();
      sp.fetchExamHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<Widget> screens = [
      const AvailableExamsTab(),
      const ExamHistoryTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('SmartExam - Student (${authProvider.user?.name ?? 'Student'})'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Performance Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerformanceAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Available Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Exam History',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          ).then((value) {
            // refresh list upon returning
            if (!context.mounted) return;
            Provider.of<StudentProvider>(context, listen: false).fetchAvailableExams();
          });
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Join Exam via QR'),
      ),
    );
  }
}

// ---------------- AVAILABLE EXAMS TAB ----------------
class AvailableExamsTab extends StatelessWidget {
  const AvailableExamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

    if (studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studentProvider.availableExams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No exams available at the moment.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await studentProvider.fetchAvailableExams();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: studentProvider.availableExams.length,
        itemBuilder: (context, index) {
          final exam = studentProvider.availableExams[index];
          return _buildExamCard(context, exam, studentProvider);
        },
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamModel exam, StudentProvider sp) {
    final isRegistered = exam.attemptStatus != null;
    final isOngoing = exam.isOngoing;
    final isUpcoming = exam.isUpcoming;

    Color badgeColor = Colors.grey;
    String badgeText = "Unavailable";

    if (isRegistered) {
      if (isOngoing) {
        badgeColor = AppColors.accent;
        badgeText = "Ready to Take";
      } else if (isUpcoming) {
        badgeColor = Colors.orangeAccent;
        badgeText = "Registered (Upcoming)";
      }
    } else {
      if (isOngoing || isUpcoming) {
        badgeColor = AppColors.primary;
        badgeText = "Registration Open";
      }
    }

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${exam.durationMinutes} Mins',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exam.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              exam.subjectName ?? 'Curriculum Subject',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Starts: ${exam.startTime.toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.lock_clock_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Marks: ${exam.totalMarks} (Pass: ${exam.passingMarks})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: isRegistered
                  ? ElevatedButton(
                      onPressed: isOngoing
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExamInstructionsScreen(exam: exam),
                                ),
                              );
                            }
                          : null,
                      child: const Text('Start Assessment'),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () async {
                        try {
                          final success = await sp.registerForExam(exam.id);
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Registered for exam successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                      child: const Text('Register Now'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- EXAM HISTORY TAB ----------------
class ExamHistoryTab extends StatelessWidget {
  const ExamHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

    if (studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studentProvider.historyExams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No exam history recorded yet.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await studentProvider.fetchExamHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: studentProvider.historyExams.length,
        itemBuilder: (context, index) {
          final exam = studentProvider.historyExams[index];
          final score = exam.score ?? 0.00;
          final pass = score >= exam.passingMarks;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                pass ? Icons.check_circle : Icons.cancel,
                color: pass ? Colors.green : Colors.red,
                size: 36,
              ),
              title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${exam.subjectName} • Score: $score / ${exam.totalMarks}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Pass the database student_exams.id if we can map it.
                      // Since history list elements return attempt status attributes, we will load details dynamically.
                      builder: (_) => ResultFeedbackScreen(exam: exam),
                    ),
                  );
                },
                child: const Text('View Result'),
              ),
            ),
          );
        },
      ),
    );
  }
}
