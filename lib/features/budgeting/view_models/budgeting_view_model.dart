import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:personal_fin/models/budgeting_state.dart';
import 'package:rxdart/rxdart.dart'; 
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';

class BudgetingViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepo;
  final TransactionRepository _txRepo; 
  final CategoryRepository _catRepo;
  final ExchangeRateService _exchangeService;
  final Stream<String> _currencyStream;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get _dbMonthKey => DateFormat('yyyy-MM').format(_selectedDate);

  BudgetingViewModel({
    required BudgetRepository budgetRepo, 
    required TransactionRepository txRepo, 
    required CategoryRepository catRepo, 
    required ExchangeRateService exchangeService, required Stream<String> currencyStream})
      :
      _budgetRepo = budgetRepo,
      _txRepo = txRepo,
      _catRepo = catRepo,
      _exchangeService = exchangeService, 
      _currencyStream = currencyStream {
    // Set initial date
    _syncDateToRepos();
  }

  // THE MASTER STATE STREAM
  Stream<BudgetingState> get stateStream {
    return Rx.combineLatest4(
      _catRepo.allCategoriesStream,
      _budgetRepo.budgetsStream,
      _txRepo.transactionsStream,
      _currencyStream, 
      (categories, budgets, transactions, currencyCode) => _calculateState(categories, budgets, transactions, currencyCode),
    );
  }

  BudgetingState _calculateState(List<Category> categories, List<Budget> budgets, List<Transaction> transactions, String currencyCode ) {
    final Map<String, double> spendingMap = {};
    
    for (var t in transactions.where((tx) => tx.type == 'Expense')) {
      final convertedAmount = _exchangeService.fromBase(t.baseAmount, currencyCode);
      spendingMap[t.categoryId] = (spendingMap[t.categoryId] ?? 0.0) + convertedAmount;
    }

    // Filter out non-expense categories
    final filteredCats = categories.where((c) => 
      !['income', 'salary', 'revenue'].any((term) => c.name.toLowerCase().contains(term))
    ).toList();

    final Map<String, double> convertedBudgetMap = {
      for (var b in budgets) 
        b.categoryId: _exchangeService.fromBase(b.baseAmount, currencyCode)
    };

    final totalBudget = budgets.fold(0.0, (sum, b) {
      return sum + _exchangeService.fromBase(b.baseAmount, currencyCode);
    });

    return BudgetingState(
      categories: filteredCats,
      transactions: transactions,
      budgetMap: convertedBudgetMap,
      spendingMap: spendingMap,
      totalBudget: totalBudget,
      activeBudgetsCount: budgets.where((b) => b.baseAmount > 0).length,
      selectedDate: _selectedDate,
      totalCategoryCount: filteredCats.length,
      currencyCode: currencyCode,
    );
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    
    // We handle the formatting internally so the UI doesn't have to
    _syncDateToRepos(); 
    
    notifyListeners();
  }

  void _syncDateToRepos() {    
    _budgetRepo.updateMonthYear(_dbMonthKey);
  }

  Future<void> setBudget(String categoryId, double amount, String currency) async {
    final uid = _budgetRepo.uid;
    final budget = Budget(
      id: '${categoryId}_$_dbMonthKey', 
      userId: uid,
      categoryId: categoryId,
      amount: amount,
      baseAmount: _exchangeService.toBase(amount, currency),
      currency: currency,
      monthYear: _dbMonthKey,
    );
    await _budgetRepo.setBudget(budget);
  }

  Future<void> refreshData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Re-sync the date to the repositories to trigger a fresh stream emission
    _syncDateToRepos();   
    notifyListeners();
  }
}

