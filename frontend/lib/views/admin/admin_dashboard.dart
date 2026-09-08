import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/theme_provider.dart';
import 'manage_users_screen.dart';
import 'manage_subjects_screen.dart';
import 'live_monitoring_screen.dart';
import '../../constants/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeacherProvider>(context, listen: false).fetchAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text('SmartExam - Admin Console'),
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
      body: teacherProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await teacherProvider.fetchAdminStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System analytics counters
                    _buildStatsGrid(teacherProvider),
                    const SizedBox(height: 35),

                    const Text(
                      'Management Portals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Navigation portal row cards
                    _buildPortalCard(
                      context,
                      'Manage Users',
                      'Create and configure Student and Examiner accounts.',
                      Icons.people_outline,
                      Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                    ),
                    _buildPortalCard(
                      context,
                      'Curriculum Catalog',
                      'Manage Courses and associate syllabus Subjects.',
                      Icons.menu_book_outlined,
                      Colors.green,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSubjectsScreen())),
                    ),
                    _buildPortalCard(
                      context,
                      'Live Proctor Monitor',
                      'Track student exam session focus infractions in real-time.',
                      Icons.visibility_outlined,
                      Colors.redAccent,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveMonitoringScreen())),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid(TeacherProvider tp) {
    final stats = tp.adminStats ?? {};
    final students = stats['students'] ?? 0;
    final teachers = stats['teachers'] ?? 0;
    final exams = stats['exams'] ?? 0;
    final active = stats['active_exams'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatTile('Students', students.toString(), Icons.people, Colors.blue),
        _buildStatTile('Teachers', teachers.toString(), Icons.person, Colors.green),
        _buildStatTile('Assessments', exams.toString(), Icons.assignment, Colors.orange),
        _buildStatTile('Live Proctoring', active.toString(), Icons.emergency_recording, Colors.redAccent),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 30),
                Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                foregroundColor: color,
                radius: 26,
                child: Icon(icon, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
