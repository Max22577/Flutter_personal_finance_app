import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/daily_finance_data.dart';
import 'package:personal_fin/models/transaction.dart';

class GraphViewModel extends ChangeNotifier {
  StreamSubscription? _sub;
  final TransactionRepository _repo;
  

  List<DailyFinanceData> dailyData = [];
  bool isLoading = true;
  String? errorMessage;

  GraphViewModel({required TransactionRepository repo, int days = 7}) 
    : _repo = repo {
    // Start listening immediately upon creation
    loadData(days);
  }

  void loadData(int daysToShow) {
    _sub?.cancel();
    _sub = _repo.transactionsStream.listen((transactions) {
      dailyData = _process(transactions, daysToShow);
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    });
  }

  List<DailyFinanceData> _process(List<Transaction> txs, int days) {
    // This is where the heavy lifting happens!
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoffDate = today.subtract(Duration(days: days));

    // Initialize map with empty data for the range
    final Map<String, DailyFinanceData> dataMap = {};
    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dataMap[dateKey] = DailyFinanceData.empty(date);
    }

    // Process only transactions within the window
    for (final t in txs) {
      if (t.date.isBefore(cutoffDate)) continue;
      
      final dateKey = DateFormat('yyyy-MM-dd').format(t.date);
      if (dataMap.containsKey(dateKey)) {
        dataMap[dateKey] = dataMap[dateKey]!.addTransaction(t.amount, t.type);
      }
    }

    final sortedData = dataMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    return sortedData;
  }

  double calculateMaxValue() {
    double max = 100;
    for (var data in dailyData) {
      if (data.income > max) max = data.income;
      if (data.expenses > max) max = data.expenses;
    }
    return (max * 1.2); // 20% head room
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}