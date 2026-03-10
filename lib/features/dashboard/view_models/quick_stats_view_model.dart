import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';

class QuickStatsViewModel extends ChangeNotifier {
  StreamSubscription? _sub;
  final TransactionRepository _repo;

  double currentMonthIncome = 0;
  double currentMonthExpenses = 0;
  double lastMonthIncome = 0;
  double lastMonthExpenses = 0;
  bool isLoading = true;

  QuickStatsViewModel(this._repo) {
    _sub = _repo.transactionsStream.listen((transactions) {
      _calculate(transactions);
      isLoading = false;
      notifyListeners();
    });
  }

  void _calculate(List<Transaction> transactions) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final last = DateTime(now.year, now.month - 1);

    // Reset values before recalculating
    currentMonthIncome = 0; currentMonthExpenses = 0;
    lastMonthIncome = 0; lastMonthExpenses = 0;

    for (final t in transactions) {
      final tMonth = DateTime(t.date.year, t.date.month);
      if (tMonth.isAtSameMomentAs(current)) {
        t.type == 'Income' ? currentMonthIncome += t.amount : currentMonthExpenses += t.amount;
      } else if (tMonth.isAtSameMomentAs(last)) {
        t.type == 'Income' ? lastMonthIncome += t.amount : lastMonthExpenses += t.amount;
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}