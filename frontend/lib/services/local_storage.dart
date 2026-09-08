import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) async {
    await init();
    return await _prefs!.setString(key, value);
  }

  static String? getString(String key) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    await init();
    return await _prefs!.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    if (_prefs == null) return null;
    final data = _prefs!.getString(key);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> remove(String key) async {
    await init();
    return await _prefs!.remove(key);
  }

  static Future<bool> clear() async {
    await init();
    return await _prefs!.clear();
  }
}
