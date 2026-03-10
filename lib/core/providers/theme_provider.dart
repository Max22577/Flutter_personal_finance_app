import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = AppThemes.lightTheme;
  ThemeMode _themeMode = ThemeMode.system;
  String _currentThemeName = 'Light';
  
  static const String _themeNameKey = 'app_theme_name';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _isFirstLaunchKey = 'is_first_app_launch';

  ThemeMode get themeMode => _themeMode;
  String get currentThemeName => _currentThemeName;

  ThemeData get currentTheme {

    if (_themeMode == ThemeMode.dark) {
      return _currentThemeName == 'Dark' ? _currentTheme : AppThemes.darkTheme;
    }
    return _currentTheme;
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;
      
      if (isFirstLaunch) {
        await prefs.setBool(_isFirstLaunchKey, false);
        await _savePreferences(); 
      } else {
        final savedThemeName = prefs.getString(_themeNameKey) ?? 'Light';
        final savedModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
        
        if (ThemeManager.themes.containsKey(savedThemeName)) {
          _currentThemeName = savedThemeName;
          _currentTheme = ThemeManager.themes[savedThemeName]!;
        }
        
        _themeMode = ThemeMode.values[savedModeIndex];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  void changeTheme(String themeName) {
    if (!ThemeManager.themes.containsKey(themeName)) return;
    
    _currentThemeName = themeName;
    _currentTheme = ThemeManager.themes[themeName]!;
    _savePreferences();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeNameKey, _currentThemeName);
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }

  void resetToDefaults() {
    _currentTheme = AppThemes.lightTheme;
    _themeMode = ThemeMode.system;
    _currentThemeName = 'Light';
    
    _savePreferences();
    
    notifyListeners();
  }
  List<String> get availableThemeNames => ThemeManager.themes.keys.toList();
}