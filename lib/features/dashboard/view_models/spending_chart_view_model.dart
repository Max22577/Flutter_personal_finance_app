import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';

class SpendingChartViewModel extends ChangeNotifier {
  final MonthlyTransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;

  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  Map<String, double> _categoryData = {};
  Map<String, double> get categoryData => _categoryData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SpendingChartViewModel(this._transactionRepo, this._categoryRepo) {
    _init();
  }

  void _init() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();

    _subscription = Rx.combineLatest2(
      _transactionRepo.stream,
      _categoryRepo.categoriesStream,
      (List<Transaction> transactions, List<Category> categories) {
        final Map<String, double> aggregatedData = {};
        
        // Filter only expenses
        final expenses = transactions.where((t) => t.type == 'Expense');

        for (var t in expenses) {
          // Find the category name using the categoryId
          final category = categories.firstWhere(
            (c) => c.id == t.categoryId,
            orElse: () => Category(id: 'unknown', name: 'Other'), // Fallback
          );

          // Add amount to that category
          aggregatedData.update(
            category.name, 
            (existingValue) => existingValue + t.amount, 
            ifAbsent: () => t.amount,
          );
        }
        return aggregatedData;
      },
    ).listen((data) {
      _categoryData = data;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    },
    onError: (error) {
      _isLoading = false;
      _errorMessage = "Could not load chart data. Please check your connection.";
      notifyListeners();
    },);
  }

  void retry() => _init();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}