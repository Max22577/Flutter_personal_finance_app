import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';

class RecentTransactionsViewModel extends ChangeNotifier {
  final TransactionRepository _repo;
  final int _maxItems;
  StreamSubscription? _sub;

  List<Transaction> _recentTransactions = [];
  List<Transaction> get recentTransactions => _recentTransactions;
  final Map<String, String> _categoryNames = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage; 
  String? get errorMessage => _errorMessage;

  String getCategoryName(String id) => _categoryNames[id] ?? 'Loading...';

  RecentTransactionsViewModel({required TransactionRepository repo, int maxItems = 5}) 
      : _repo = repo, _maxItems = maxItems {
    _init();
  }

  void _init() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _repo.transactionsStream.listen((transactions) async {
      try {
        final sorted = List<Transaction>.from(transactions)
          ..sort((a, b) => b.date.compareTo(a.date));
        
        _recentTransactions = sorted.take(_maxItems).toList();
        await _fetchCategoryNames();
        
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      } catch (e) {
        _handleError("Failed to process transactions");
      }
    }, onError: (e) {
      _handleError("Connection to transactions lost");
    });
  }

  void _handleError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void retry() => _init();

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