import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/services/preferences.dart';

class DateFormatProvider extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  String _currentPattern = 'dd/MM/yyyy'; // Default fallback

  String get currentPattern => _currentPattern;

  Future<void> init() async {
    _currentPattern = await _prefs.getDateFormat();
    notifyListeners();
  }

  Future<void> updateDateFormat(String pattern) async {
    _currentPattern = pattern;
    await _prefs.setDateFormat(pattern);
    notifyListeners();
  }

  /// Helper utility to format any date directly from the UI using the current layout and locale
  String format(DateTime date, String localeCode) {
    return DateFormat(_currentPattern, localeCode).format(date);
  }
}