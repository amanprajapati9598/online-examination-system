import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_themes.dart';
import 'providers/auth_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/student_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/theme_provider.dart';
import 'services/local_storage.dart';

import 'views/auth/login_screen.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/teacher/teacher_dashboard.dart';
import 'views/student/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: const SmartExamApp(),
    ),
  );
}

class SmartExamApp extends StatelessWidget {
  const SmartExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'SmartExam',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: authProvider.isAuthenticated
          ? _getDashboardForRole(authProvider.user?.role)
          : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin-dashboard': (_) => const AdminDashboard(),
        '/teacher-dashboard': (_) => const TeacherDashboard(),
        '/student-dashboard': (_) => const StudentDashboard(),
      },
    );
  }

  Widget _getDashboardForRole(String? role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'teacher':
        return const TeacherDashboard();
      case 'student':
        return const StudentDashboard();
      default:
        return const LoginScreen();
    }
  }
}
