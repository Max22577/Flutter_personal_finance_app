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

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  BudgetingViewModel(this._budgetRepo, this._txRepo, this._catRepo, {required ExchangeRateService exchangeService})
      : _exchangeService = exchangeService {
    // Set initial date
    _syncDateToRepos();
  }

  // THE MASTER STATE STREAM
  Stream<BudgetingState> get stateStream {
    return Rx.combineLatest3(
      _catRepo.allCategoriesStream,
      _budgetRepo.budgetsStream,
      _txRepo.transactionsStream, 
      (categories, budgets, transactions) => _calculateState(categories, budgets, transactions),
    );
  }

  BudgetingState _calculateState(List<Category> categories, List<Budget> budgets, List<Transaction> transactions) {
    final Map<String, double> spendingMap = {};
    
    for (var t in transactions.where((tx) => tx.type == 'Expense')) {
      spendingMap[t.categoryId] = (spendingMap[t.categoryId] ?? 0.0) + t.baseAmount;
    }

    // Filter out non-expense categories
    final filteredCats = categories.where((c) => 
      !['income', 'salary', 'revenue'].any((term) => c.name.toLowerCase().contains(term))
    ).toList();

    return BudgetingState(
      categories: filteredCats,
      transactions: transactions,
      budgetMap: {for (var b in budgets) b.categoryId: b.baseAmount},
      spendingMap: spendingMap,
      totalBudget: budgets.fold(0.0, (sum, b) => sum + b.baseAmount),
      activeBudgetsCount: budgets.where((b) => b.baseAmount > 0).length,
      monthYear: DateFormat('MMMM yyyy').format(_selectedDate),
      totalCategoryCount: filteredCats.length,
    );
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    
    // We handle the formatting internally so the UI doesn't have to
    _syncDateToRepos(); 
    
    notifyListeners();
  }

  void _syncDateToRepos() {
    // Ensure we use a consistent format across the app (usually 'MMMM yyyy')
    final formatted = DateFormat('MMMM yyyy').format(_selectedDate);
    
    _budgetRepo.updateMonthYear(formatted);

  }

  Future<void> setBudget(String categoryId, double amount, String currency) async {
    final formatted = DateFormat('MMMM yyyy').format(_selectedDate);
    final uid = _budgetRepo.uid;
    final budget = Budget(
      id: '${categoryId}_$formatted', 
      userId: uid,
      categoryId: categoryId,
      amount: amount,
      baseAmount: _exchangeService.toBase(amount, currency),
      currency: currency,
      monthYear: formatted,
    );
    await _budgetRepo.setBudget(budget);
  }

  Future<void> refreshData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Re-sync the date to the repositories to trigger a fresh stream emission
    _syncDateToRepos();
    
    // If you have specific refresh logic in repos, call it here
    // await _budgetRepo.refresh();
    
    notifyListeners();
  }
}

