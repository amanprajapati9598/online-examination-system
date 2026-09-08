import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = LocalStorage.getString('theme_mode');
    _isDarkMode = (mode == 'dark');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await LocalStorage.setString('theme_mode', _isDarkMode ? 'dark' : 'light');
    notifyListeners();
  }
}
