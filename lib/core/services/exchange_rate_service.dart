import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/models/exchange_rate.dart';

class ExchangeRateService extends ChangeNotifier {
  final Map<String, ExchangeRate> _cachedRates = {};
  final String _appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');
  
  static const String baseCurrencyCode = 'USD';
  bool _hasStarted = false;
  
  ExchangeRateService() {
    init(); 
  }
  
  CollectionReference _exchangeRatesRef() {
    final path = 'artifacts/$_appId/rates';
    
    if (_appId.isEmpty) {
      throw Exception("CRITICAL: APP_ID is empty.");
    }

    return FirebaseFirestore.instance.collection(path); 
  }

  CollectionReference get exchangeRatesRef => _exchangeRatesRef();
  
  void init() {
    if (_hasStarted || _appId.isEmpty) return;
    _hasStarted = true;
    
    _exchangeRatesRef().snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final rate = ExchangeRate.fromMap(doc.data() as Map<String, dynamic>);
        _cachedRates[rate.code] = rate;
      }
      notifyListeners(); 
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
    if (rate == null){ 
      debugPrint("CRITICAL ERROR: No exchange rate found for currency: $toCode");
      return amountInBase;
    }
    
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