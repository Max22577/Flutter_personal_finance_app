import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/preferences.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:rxdart/rxdart.dart';

class CurrencyProvider extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  String _currentCurrency = 'KES';

  final _currencySubject = BehaviorSubject<String>.seeded('KES');

  String get currentCurrency => _currentCurrency;
  Stream<String> get currencyStream => _currencySubject.stream;
  Currency get currency => Currency.getCurrency(_currentCurrency);

  // Initialize and load from storage
  Future<void> init() async {
    String? savedCurrency = await _prefs.getCurrency();

    if (savedCurrency == 'KSH') {
      savedCurrency = 'KES';
      await _prefs.setCurrency('KES'); 
    }
    _currentCurrency = savedCurrency; 
    _currencySubject.add(_currentCurrency);
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
    _currencySubject.add(newCode);
    
    notifyListeners(); 
  }
}