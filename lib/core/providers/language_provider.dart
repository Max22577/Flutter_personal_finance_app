import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/preferences.dart';
import 'package:personal_fin/core/utils/translations.dart';
import 'package:rxdart/rxdart.dart';

class LanguageProvider extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  String _currentLanguage = 'English'; // Display name
  String _localeCode = 'en';          // ISO code for logic

  final _localeSubject = BehaviorSubject<String>.seeded('en');
  Stream<String> get localeStream => _localeSubject.stream;

  String get currentLanguage => _currentLanguage;
  String get localeCode => _localeCode;

  Future<void> init() async {
    _currentLanguage = await _prefs.getLanguage();
    // Map display name to code or store code directly in prefs
    _localeCode = _mapLanguageToCode(_currentLanguage);
    _localeSubject.add(_localeCode);
    notifyListeners();
  }

  Future<void> updateLanguage(String languageName) async {
    _currentLanguage = languageName;
    _localeCode = _mapLanguageToCode(languageName);
    await _prefs.setLanguage(languageName);
    // Update the stream so ViewModels react immediately
    _localeSubject.add(_localeCode);
    notifyListeners(); 
  }

  String _mapLanguageToCode(String name) {
    return switch (name) {
      'English' => 'en',
      'Swahili' => 'sw',
      'French' => 'fr',
      'Spanish' => 'es',
      _ => 'en',
    };
  }

  String translate(String key) {
    return Translations.get(key, _localeCode);
  }

  @override
  void dispose() {
    _localeSubject.close();
    super.dispose();
  }
}