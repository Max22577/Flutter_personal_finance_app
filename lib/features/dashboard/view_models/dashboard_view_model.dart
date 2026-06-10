import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:rxdart/rxdart.dart';
import '../../../models/monthly_data.dart';

class DashboardViewModel extends ChangeNotifier  {
  final MonthlyDataRepository _repo;
  final CurrencyProvider _currencyProvider;

  MonthlyData? currentMonthData;
  MonthlyData? previousMonthData;
  bool isLoading = true;
  String? errorMessage;

  DashboardViewModel(this._repo, this._currencyProvider);

  DateTime _selectedMonth = DateTime.now();
  
  Stream<List<MonthlyData>> get dashboardReviewStream {
    return _currencyProvider.currencyStream.switchMap((currency) {
      return _repo.streamReviewData(_selectedMonth, currency);
    });
  }

  void updateMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners(); 
  }

  Future<void> refresh() async {
    notifyListeners(); 

    await Future.delayed(const Duration(milliseconds: 500));
  }
}