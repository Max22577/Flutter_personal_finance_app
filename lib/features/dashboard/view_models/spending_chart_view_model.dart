import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:rxdart/rxdart.dart';

class SpendingChartViewModel extends ChangeNotifier {
  final MonthlyDataRepository _repo;
  final CategoryRepository _catRepo;
  final CurrencyProvider _currencyProvider;

  SpendingChartViewModel(this._repo, this._catRepo, this._currencyProvider);
  
  Stream<Map<String, double>> get spendingMapStream {
    return _currencyProvider.currencyStream.switchMap((currency) {

      return _repo.streamMonthlyData(DateTime.now(), currency).map((data) {
        final Map<String, double> namedMap = {};
      
        data.categoryBreakdown.forEach((categoryId, amount) {
          final category = _catRepo.getCategoryByIdSync(categoryId);
        
          if (category != null) {
            namedMap[category.name] = amount;
          } else {
            // Fallback if category was deleted or not found
            namedMap['Unknown'] = (namedMap['Unknown'] ?? 0.0) + amount;
          }
        });
        
        return namedMap; 
      });
    });
  }
}