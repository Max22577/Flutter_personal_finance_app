import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/apis/currency_api_service.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/preferences.dart';

class RateSyncProvider extends ChangeNotifier {
  final CurrencyApiService _apiService = CurrencyApiService();
  final ExchangeRateService _exchangeRateService;
  final PreferencesService _prefs = PreferencesService();

  RateSyncProvider({required ExchangeRateService exchangeRateService})
      : _exchangeRateService = exchangeRateService;

  Future<void> syncRates({bool force = false}) async {
    final needsSync = await _prefs.shouldSyncRates();
    
    if (!needsSync && !force) {
      debugPrint("RateSyncProvider: Skipping sync, rates are up to date.");
      return;
    }

    try {
      final newRates = await _apiService.fetchLatestRates();
      
      if (newRates != null) {
        final collectionRef = _exchangeRateService.exchangeRatesRef; 
        final batch = FirebaseFirestore.instance.batch();
        final now = DateTime.now();

        final List<String> codesToSync = ['USD', 'EUR', 'GBP', 'JPY', 'KES', 'ZAR', 'NGN', 'GHS']; 

        for (var code in codesToSync) {
          if (newRates.containsKey(code)) {
            final docRef = collectionRef.doc(code);
            
            final rateData = {
              'code': code,
              'rateToBase': newRates[code],
              'timestamp': FieldValue.serverTimestamp(), // Better for Firestore sync
            };

            batch.set(docRef, rateData, SetOptions(merge: true));
          }
        }

        await batch.commit();
        await _prefs.setLastRateSync(now);
        debugPrint("Currency Sync Successful: ${codesToSync.length} rates updated.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("CRITICAL Error during rate sync: $e");
    }
  }
}