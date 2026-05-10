import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/apis/currency_api_service.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:personal_fin/models/exchange_rate.dart';

class RateSyncProvider extends ChangeNotifier {
  final CurrencyApiService _apiService = CurrencyApiService();
  final FirestoreService _firestoreService; 

  RateSyncProvider(this._firestoreService);

  Future<void> syncRates() async {
    final newRates = await _apiService.fetchLatestRates();
    
    if (newRates != null) {
      // Get the correct collection reference from your service
      final collectionRef = await _firestoreService.ratesCollectionRef();
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      final supportedCodes = Currency.getCurrencyCodes();

      for (var code in supportedCodes) {
        if (newRates.containsKey(code)) {
          // Use the dynamic path from your service
          final docRef = collectionRef.doc(code);
          
          final rateObject = ExchangeRate(
            code: code,
            rateToBase: newRates[code]!,
            timestamp: now,
          );

          batch.set(docRef, rateObject.toMap());
        }
      }

      await batch.commit();
      notifyListeners();
    }
  }
}