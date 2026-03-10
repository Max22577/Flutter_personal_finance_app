import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/services/preferences.dart';
import 'package:provider/provider.dart';


class GeneralSettingsViewModel extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  
  // State variables
  String currency = 'USD';
  String language = 'English';
  String dateFormat = 'MM/DD/YYYY';
  String numberFormat = '1,234.56';
  bool isLoading = true;

  // Initialize and load preferences
  Future<void> loadSettings() async {
    try {
      currency = await _prefs.getCurrency();
      language = await _prefs.getLanguage();
      dateFormat = await _prefs.getDateFormat();
      numberFormat = await _prefs.getNumberFormat();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Generic update method to avoid code repetition
  Future<void> updateSetting(String id, String value) async {
    switch (id) {
      case 'currency':
        currency = value;
        await _prefs.setCurrency(value);
        break;
      case 'language':
        language = value;
        await _prefs.setLanguage(value);
        break;
      case 'date_format':
        dateFormat = value;
        await _prefs.setDateFormat(value);
        break;
      case 'number_format':
        numberFormat = value;
        await _prefs.setNumberFormat(value);
        break;
    }
    notifyListeners();
  }

  Future<void> updateCurrency(BuildContext context, String code) async {
    currency = code;
    
    await _prefs.setCurrency(code);
  
    if (context.mounted) {
      await context.read<CurrencyProvider>().updateCurrency(code);
    }
    notifyListeners(); 
  }

  Future<void> updateLanguage(BuildContext context, String langName) async {
    language = langName;
    
    await _prefs.setLanguage(langName);
    
    if (context.mounted) {
      await context.read<LanguageProvider>().updateLanguage(langName);
    }
    
    notifyListeners(); // Refresh the UI
  }

  Future<void> resetAll() async {
    await _prefs.clearAll();
    await loadSettings();
  }
}