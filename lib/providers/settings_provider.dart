import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _userName = 'Alex Johnson';
  bool _isDarkMode = true;

  String get userName => _userName;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  static const _keyUserName = 'user_name';
  static const _keyDarkMode = 'is_dark_mode';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_keyUserName) ?? 'Alex Johnson';
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim().isEmpty ? 'Alex Johnson' : name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, _userName);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }
}
