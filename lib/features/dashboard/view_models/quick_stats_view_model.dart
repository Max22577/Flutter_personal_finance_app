import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/transaction.dart';

class QuickStatsViewModel extends ChangeNotifier {
  StreamSubscription? _sub;
  final TransactionRepository _repo;
  final ExchangeRateService _exchangeService;
  final CurrencyProvider _currencyProvider;

  double currentMonthIncome = 0;
  double currentMonthExpenses = 0;
  double lastMonthIncome = 0;
  double lastMonthExpenses = 0;
  bool isLoading = true;

  QuickStatsViewModel(this._repo, this._exchangeService, this._currencyProvider) {
    _sub = _repo.transactionsStream.listen((transactions) {
      _calculate(transactions, _currencyProvider.currentCurrency);
      isLoading = false;
      notifyListeners();
    });
  }

  void _calculate(List<Transaction> transactions, String currencyCode) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final last = DateTime(now.year, now.month - 1);

    // Reset values before recalculating
    currentMonthIncome = 0; currentMonthExpenses = 0;
    lastMonthIncome = 0; lastMonthExpenses = 0;

    for (final t in transactions) {
      final tMonth = DateTime(t.date.year, t.date.month);
      final tAmountInTarget = _exchangeService.fromBase(t.baseAmount, currencyCode);
      if (tMonth.isAtSameMomentAs(current)) {
        t.type == 'Income' ? currentMonthIncome += tAmountInTarget : currentMonthExpenses += tAmountInTarget;
      } else if (tMonth.isAtSameMomentAs(last)) {
        t.type == 'Income' ? lastMonthIncome += tAmountInTarget : lastMonthExpenses += tAmountInTarget;
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}