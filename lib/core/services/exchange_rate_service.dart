import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/exchange_rate.dart';

class ExchangeRateService extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final Map<String, ExchangeRate> _cachedRates = {};
  
  static const String baseCurrencyCode = 'USD';

  // Constructor starts the listener immediately
  ExchangeRateService(this._firestoreService) {
    _initRateListener();
  }

  void _initRateListener() async {
    final ref = await _firestoreService.ratesCollectionRef();
    
    // Listen to real-time updates from Firestore
    ref.snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final rate = ExchangeRate.fromMap(doc.data() as Map<String, dynamic>);
        _cachedRates[rate.code] = rate;
      }
      notifyListeners(); // This is what updates your UI!
    });
  }

  double getRateToBase(String code) {
    return _cachedRates[code]?.rateToBase ?? 1.0;
  }

  /// Converts an amount from one currency to another
  double convert({
    required double amount,
    required String fromCode,
    required String toCode,
  }) {
    if (fromCode == toCode) return amount;

    // Convert "From" currency to "Base" (USD)
    // Formula: amount / rateOfFromCurrency
    final double amountInBase = toBase(amount, fromCode);

    // Convert "Base" (USD) to "Target" currency
    // Formula: amountInBase * rateOfToCurrency
    return fromBase(amountInBase, toCode);
  }

  /// Helper: Convert any currency to USD
  double toBase(double amount, String fromCode) {
    if (fromCode == baseCurrencyCode) return amount;
    
    final rate = _cachedRates[fromCode]?.rateToBase;
    if (rate == null || rate == 0) return amount; // Fallback to 1:1 if rate missing
    
    return amount / rate;
  }

  /// Helper: Convert USD to any currency
  double fromBase(double amountInBase, String toCode) {
    if (toCode == baseCurrencyCode) return amountInBase;
    
    final rate = _cachedRates[toCode]?.rateToBase;
    if (rate == null) return amountInBase;
    
    return amountInBase * rate;
  }

  // Method to update rates from your API
  void updateRates(List<ExchangeRate> newRates) {
    for (var rate in newRates) {
      _cachedRates[rate.code] = rate;
    }
    notifyListeners();
  }
}