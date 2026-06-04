import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:rxdart/rxdart.dart';

class SpendingChartViewModel extends ChangeNotifier {
  final MonthlyDataRepository _repo;
  final CurrencyProvider _currencyProvider;

  SpendingChartViewModel(this._repo, this._currencyProvider);
  
  Stream<Map<String, double>> get spendingMapStream {
    return _currencyProvider.currencyStream.switchMap((currency) {

      return _repo.streamMonthlyData(DateTime.now(), currency).map((data) {
        return data.categoryBreakdown; 
      });
    });
  }
}