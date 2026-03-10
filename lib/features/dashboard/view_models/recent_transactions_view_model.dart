import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';

class RecentTransactionsViewModel extends ChangeNotifier {
  final TransactionRepository _repo;
  StreamSubscription? _sub;

  List<Transaction> recentTransactions = [];
  bool isLoading = true;

  RecentTransactionsViewModel({required TransactionRepository repo, int maxItems = 5}) 
      : _repo = repo {
    _sub = _repo.transactionsStream.listen((transactions) {
      // Logic: Sort by newest first and take the limit
      final sorted = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      
      recentTransactions = sorted.take(maxItems).toList();
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}