import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/category_spending.dart';

class SpendingChartViewModel extends ChangeNotifier {
  final TransactionRepository _repository;
  final CurrencyProvider _currencyProvider;

  SpendingChartViewModel(this._repository, this._currencyProvider);
 
  Stream<Map<String, double>> get spendingMapStream {
    return _repository.getMonthlySpendingStream(DateTime.now(), _currencyProvider.currentCurrency)
        .map((List<CategorySpending> spendingList) {
      // Transform the List into a Map<String, double>
      return {
        for (var item in spendingList) item.category.name: item.totalAmount
      };
    });
  }
}