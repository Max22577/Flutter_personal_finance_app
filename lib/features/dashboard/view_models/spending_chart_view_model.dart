import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';

class SpendingChartViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final ExchangeRateService _exchangeService;
  final Stream<String> _currencyStream;

  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  Map<String, double> _categoryData = {};
  Map<String, double> get categoryData => _categoryData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SpendingChartViewModel(
    this._transactionRepo, 
    this._categoryRepo, 
    this._exchangeService, 
    {required Stream<String> currencyStream}) : _currencyStream = currencyStream {
    _init();
  }

  void _init() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();

    _subscription = Rx.combineLatest3(
      _transactionRepo.monthlyTransactionsStream,
      _categoryRepo.allCategoriesStream,
      _currencyStream,
      (List<Transaction> transactions, List<Category> categories, String currencyCode) {
        final Map<String, double> aggregatedData = {};
        
        // Filter only expenses
        final expenses = transactions.where((t) => t.type == 'Expense');

        for (var t in expenses) {
          // Find the category name using the categoryId
          final category = categories.firstWhere(
            (c) => c.id == t.categoryId,
            orElse: () => Category(id: 'unknown', name: 'Other'), // Fallback
          );

          final convertedAmount = _exchangeService.fromBase(t.baseAmount, currencyCode);

          // Add amount to that category
          aggregatedData.update(
            category.name, 
            (existingValue) => existingValue + convertedAmount, 
            ifAbsent: () => convertedAmount,
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