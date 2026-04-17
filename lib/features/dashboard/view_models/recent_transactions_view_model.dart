import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';

class RecentTransactionsViewModel extends ChangeNotifier {
  final TransactionRepository _repo;
  StreamSubscription? _sub;

  List<Transaction> _recentTransactions = [];
  List<Transaction> get recentTransactions => _recentTransactions;
  final Map<String, String> _categoryNames = {};
  bool isLoading = true;

  String getCategoryName(String id) => _categoryNames[id] ?? 'Loading...';

  RecentTransactionsViewModel({required TransactionRepository repo, int maxItems = 5}) 
      : _repo = repo {
    _sub = _repo.transactionsStream.listen((transactions) async {
      // Logic: Sort by newest first and take the limit
      final sorted = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      
      _recentTransactions = sorted.take(maxItems).toList();
      await _fetchCategoryNames();
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchCategoryNames() async {
    final ids = _recentTransactions.map((tx) => tx.categoryId).toSet();

    for (final id in ids) {
      if (!_categoryNames.containsKey(id)) {
        final name = await _repo.getCategoryName(id);
        _categoryNames[id] = name;
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}