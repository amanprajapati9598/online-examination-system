import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/student_exam_model.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class StudentProvider with ChangeNotifier {
  List<ExamModel> _availableExams = [];
  List<ExamModel> _historyExams = [];
  bool _isLoading = false;

  // Active Exam State
  int? _activeStudentExamId;
  List<QuestionModel> _activeQuestions = [];
  int _activeDurationMinutes = 0;
  int _secondsRemaining = 0;
  Timer? _examTimer;
  bool _antiCheatingEnabled = false;
  int _tabSwitches = 0;
  final int _maxTabSwitches = 3;
  bool _examSubmitted = false;

  // Analytics Overview
  Map<String, dynamic>? _analyticsSummary;
  List<dynamic> _analyticsProgression = [];
  List<LeaderboardModel> _leaderboard = [];

  List<ExamModel> get availableExams => _availableExams;
  List<ExamModel> get historyExams => _historyExams;
  bool get isLoading => _isLoading;

  int? get activeStudentExamId => _activeStudentExamId;
  List<QuestionModel> get activeQuestions => _activeQuestions;
  int get secondsRemaining => _secondsRemaining;
  bool get antiCheatingEnabled => _antiCheatingEnabled;
  int get tabSwitches => _tabSwitches;
  int get maxTabSwitches => _maxTabSwitches;
  bool get examSubmitted => _examSubmitted;

  Map<String, dynamic>? get analyticsSummary => _analyticsSummary;
  List<dynamic> get analyticsProgression => _analyticsProgression;
  List<LeaderboardModel> get leaderboard => _leaderboard;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchAvailableExams() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.availableExams);
      if (res['success'] == true) {
        var list = res['exams'] as List? ?? [];
        _availableExams = list.map((e) => ExamModel.fromJson(e)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchExamHistory() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.examHistory);
      if (res['success'] == true) {
        var list = res['history'] as List? ?? [];
        _historyExams = list.map((e) => ExamModel.fromJson(e)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> registerForExam(int examId, {String? qrToken}) async {
    _setLoading(true);
    try {
      final payload = qrToken != null ? {'qr_token': qrToken} : {'exam_id': examId};
      final res = await ApiService.post(ApiEndpoints.registerExam, payload);
      _setLoading(false);
      if (res['success'] == true) {
        fetchAvailableExams();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> startExam(int examId) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.startExam, {'exam_id': examId});
      if (res['success'] == true) {
        _activeStudentExamId = int.parse(res['student_exam_id'].toString());
        _activeDurationMinutes = int.parse(res['duration_minutes'].toString());
        _antiCheatingEnabled = res['anti_cheating_enabled'].toString() == '1' || res['anti_cheating_enabled'] == true;
        
        var list = res['questions'] as List? ?? [];
        _activeQuestions = list.map((q) => QuestionModel.fromJson(q)).toList();
        
        _secondsRemaining = _activeDurationMinutes * 60;
        _tabSwitches = 0;
        _examSubmitted = false;

        _startTimer();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  void _startTimer() {
    _examTimer?.cancel();
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _examTimer?.cancel();
        // Time ran out, trigger auto submission
        submitExam(autoSubmitted: true);
      }
    });
  }

  Future<void> selectAnswer(int questionIndex, int optionId) async {
    final question = _activeQuestions[questionIndex];
    question.selectedOptionId = optionId;
    notifyListeners();

    // Autosave response asynchronously in background
    try {
      await ApiService.post(ApiEndpoints.saveAnswer, {
        'student_exam_id': _activeStudentExamId,
        'question_id': question.id,
        'selected_option_id': optionId,
      });
    } catch (_) {
      // Background save fail shouldn't interrupt student's test session
    }
  }

  Future<void> logCheatingIncident(String eventType, String details) async {
    if (!_antiCheatingEnabled || _activeStudentExamId == null) return;
    
    if (eventType == 'tab_switch') {
      _tabSwitches++;
      notifyListeners();
    }

    try {
      await ApiService.post(ApiEndpoints.cheatingLog, {
        'student_exam_id': _activeStudentExamId,
        'event_type': eventType,
        'details': details,
      });
    } catch (_) {}

    // Check if limit crossed
    if (eventType == 'tab_switch' && _tabSwitches >= _maxTabSwitches) {
      submitExam(autoSubmitted: true);
    }
  }

  Future<Map<String, dynamic>> submitExam({bool autoSubmitted = false}) async {
    _examTimer?.cancel();
    if (_activeStudentExamId == null || _examSubmitted) {
      return {'success': false, 'message': 'No active exam session'};
    }

    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.submitExam, {
        'student_exam_id': _activeStudentExamId,
        'auto_submitted': autoSubmitted ? 1 : 0,
      });

      if (res['success'] == true) {
        _examSubmitted = true;
        _activeStudentExamId = null;
        _activeQuestions = [];
        notifyListeners();
        
        fetchAvailableExams();
        fetchExamHistory();
        
        _setLoading(false);
        return res;
      }
      _setLoading(false);
      return {'success': false, 'message': 'Submission failed'};
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchStudentAnalytics() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.studentAnalytics);
      if (res['success'] == true) {
        _analyticsSummary = res['summary'] as Map<String, dynamic>?;
        _analyticsProgression = res['progression'] as List? ?? [];
        
        var list = res['leaderboard'] as List? ?? [];
        _leaderboard = list.map((l) => LeaderboardModel.fromJson(l)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    super.dispose();
  }
}
