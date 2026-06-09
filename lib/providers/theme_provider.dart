import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'kurachi_is_dark_theme';
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_themeKey) ?? false;
      AppConfig.isDark = _isDark;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isDark = !_isDark;
      AppConfig.isDark = _isDark;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDark);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
