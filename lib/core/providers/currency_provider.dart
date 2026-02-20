import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/preferences.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/models/currency.dart';

class CurrencyProvider extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  String _currentCurrency = 'KSH';

  String get currentCurrency => _currentCurrency;
  Currency get currency => Currency.getCurrency(_currentCurrency);

  // Initialize and load from storage
  Future<void> init() async {
    _currentCurrency = await _prefs.getCurrency();
    notifyListeners();
  }

  // Create a formatter instance that updates whenever the code changes
  CurrencyFormatter get formatter => CurrencyFormatter(currency);

  // The method your Settings page will call
  Future<void> updateCurrency(String newCode) async {
    _currentCurrency = newCode;
    await _prefs.setCurrency(newCode);
    
    notifyListeners(); 
  }
}