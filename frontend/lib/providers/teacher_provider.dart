import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/student_exam_model.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class TeacherProvider with ChangeNotifier {
  List<StudentExamModel> _activeExams = [];
  List<UserModel> _users = [];
  Map<String, dynamic>? _teacherStats;
  Map<String, dynamic>? _adminStats;
  bool _isLoading = false;

  List<StudentExamModel> get activeExams => _activeExams;
  List<UserModel> get users => _users;
  Map<String, dynamic>? get teacherStats => _teacherStats;
  Map<String, dynamic>? get adminStats => _adminStats;
  bool get isLoading => _isLoading;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchTeacherStats() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.teacherStats);
      if (res['success'] == true) {
        _teacherStats = res['stats'] as Map<String, dynamic>?;
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchAdminStats() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.systemStats);
      if (res['success'] == true) {
        _adminStats = res['stats'] as Map<String, dynamic>?;
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchActiveExams() async {
    _setLoading(true);
    try {
      final res = await ApiService.get(ApiEndpoints.activeExams);
      if (res['success'] == true) {
        var list = res['active_exams'] as List? ?? [];
        _activeExams = list.map((e) => StudentExamModel.fromJson(e)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchUsers({String? role, String? search}) async {
    _setLoading(true);
    try {
      final Map<String, String> params = {};
      if (role != null) params['role'] = role;
      if (search != null) params['search'] = search;

      final res = await ApiService.get(ApiEndpoints.adminUsers, queryParams: params);
      if (res['success'] == true) {
        var list = res['users'] as List? ?? [];
        _users = list.map((u) => UserModel.fromJson(u)).toList();
      }
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> createUser(String name, String email, String password, String role) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.adminUsers, {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      _setLoading(false);
      if (res['success'] == true) {
        fetchUsers(role: role);
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> updateUser(int id, String name, String email, String status, String? role) async {
    _setLoading(true);
    try {
      final res = await ApiService.put('${ApiEndpoints.adminUsers}?id=$id', {
        'name': name,
        'email': email,
        'status': status,
        if (role != null) 'role': role,
      });
      _setLoading(false);
      if (res['success'] == true) {
        fetchUsers(role: role);
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> deleteUser(int id, {String? role}) async {
    _setLoading(true);
    try {
      final res = await ApiService.delete('${ApiEndpoints.adminUsers}?id=$id');
      _setLoading(false);
      if (res['success'] == true) {
        _users.removeWhere((u) => u.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> uploadCSV(int examId, String filePath) async {
    _setLoading(true);
    try {
      final res = await ApiService.uploadMultipart(
        ApiEndpoints.bulkUploadQuestions,
        filePath,
        {'exam_id': examId.toString()},
      );
      _setLoading(false);
      return res['success'] == true;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }
}
