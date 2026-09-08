class ApiEndpoints {
  // In XAMPP, this is the relative root path
  // If running in Android Emulator, replace localhost with 10.0.2.2
  static const String baseUrl = 'http://localhost/online-examination-system/backend/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String changePassword = '/auth/change-password';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminCourses = '/admin/courses';
  static const String adminSubjects = '/admin/subjects';
  static const String activeExams = '/admin/exams/active';
  static const String systemStats = '/admin/stats';
  static const String systemSettings = '/admin/settings';

  // Teacher
  static const String teacherExams = '/teacher/exams';
  static const String teacherQuestions = '/teacher/questions';
  static const String bulkUploadQuestions = '/teacher/questions/bulk';
  static const String examResults = '/teacher/results';
  static const String teacherStats = '/teacher/stats';

  // Student
  static const String availableExams = '/student/exams/available';
  static const String registerExam = '/student/exams/register';
  static const String startExam = '/student/exams/start';
  static const String saveAnswer = '/student/exams/save-answer';
  static const String cheatingLog = '/student/exams/cheating-log';
  static const String submitExam = '/student/exams/submit';
  static const String examHistory = '/student/exams/history';
  static const String examResultDetails = '/student/exams/result';
  static const String studentAnalytics = '/student/analytics';

  // Reports
  static const String downloadReport = 'http://localhost/online-examination-system/backend/api/reports/result/download';
  static const String exportCSV = 'http://localhost/online-examination-system/backend/api/reports/results/export';
}
