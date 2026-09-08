import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../constants/api_endpoints.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    tryAutoLogin();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = LocalStorage.getString('jwt_token');
    final userJson = LocalStorage.getJson('user_profile');
    
    if (token != null && userJson != null) {
      _token = token;
      _user = UserModel.fromJson(userJson);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (res['success'] == true) {
        _token = res['token'] as String;
        _user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        
        await LocalStorage.setString('jwt_token', _token!);
        await LocalStorage.setJson('user_profile', _user!.toJson());
        
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.register, {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      _setLoading(false);
      return res['success'] == true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await LocalStorage.remove('jwt_token');
    await LocalStorage.remove('user_profile');
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.changePassword, {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      _setLoading(false);
      return res['success'] == true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      final res = await ApiService.post(ApiEndpoints.forgotPassword, {
        'email': email,
      });
      _setLoading(false);
      return res['success'] == true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
}
