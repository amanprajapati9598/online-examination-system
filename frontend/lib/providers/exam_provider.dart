import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../models/course_model.dart';
import '../models/subject_model.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class ExamProvider with ChangeNotifier {
  List<ExamModel> _exams = [];
  List<CourseModel> _courses = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = false;

  List<ExamModel> get exams => _exams;
  List<CourseModel> get courses => _courses;
  List<SubjectModel> get subjects => _subjects;
  bool get isLoading => _isLoading;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchExams() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.teacherExams);
      if (res['success'] == true) {
        var list = res['exams'] as List? ?? [];
        _exams = list.map((e) => ExamModel.fromJson(e)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchCourses() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.adminCourses);
      if (res['success'] == true) {
        var list = res['courses'] as List? ?? [];
        _courses = list.map((e) => CourseModel.fromJson(e)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchSubjects({int? courseId}) async {
    _setLoading(true);
    try {
      final Map<String, String> params = {};
      if (courseId != null) {
        params['course_id'] = courseId.toString();
      }
      final res = await ApiService.get(ApiEndpoints.adminSubjects, queryParams: params);
      if (res['success'] == true) {
        var list = res['subjects'] as List? ?? [];
        _subjects = list.map((e) => SubjectModel.fromJson(e)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> createExam(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.teacherExams, data);
      _setLoading(false);
      if (res['success'] == true) {
        fetchExams();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> updateExam(int examId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await ApiService.put('${ApiEndpoints.teacherExams}?id=$examId', data);
      _setLoading(false);
      if (res['success'] == true) {
        fetchExams();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> deleteExam(int examId) async {
    _setLoading(true);
    try {
      final res = await ApiService.delete('${ApiEndpoints.teacherExams}?id=$examId');
      _setLoading(false);
      if (res['success'] == true) {
        _exams.removeWhere((e) => e.id == examId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> createCourse(String name, String code, String description) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.adminCourses, {
        'name': name,
        'code': code,
        'description': description,
      });
      _setLoading(false);
      if (res['success'] == true) {
        fetchCourses();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> createSubject(int courseId, String name, String code, String description) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.adminSubjects, {
        'course_id': courseId,
        'name': name,
        'code': code,
        'description': description,
      });
      _setLoading(false);
      if (res['success'] == true) {
        fetchSubjects();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }
}
