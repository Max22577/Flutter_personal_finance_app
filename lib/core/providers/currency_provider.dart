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

  CurrencyFormatter? _cachedFormatter;

  CurrencyFormatter get formatter {
    _cachedFormatter ??= CurrencyFormatter(currency);
    return _cachedFormatter!;
  }

  Future<void> updateCurrency(String newCode) async {
    _currentCurrency = newCode;
    _cachedFormatter = null;
    await _prefs.setCurrency(newCode);
    
    notifyListeners(); 
  }
}