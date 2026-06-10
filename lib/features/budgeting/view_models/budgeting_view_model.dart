import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:personal_fin/models/state_models/budgeting_state.dart';
import 'package:rxdart/rxdart.dart'; 


class BudgetingViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepo;
  final MonthlyDataRepository _monthlyDataRepo; 
  final CategoryRepository _catRepo;
  final ExchangeRateService _exchangeService;
  final CurrencyProvider _currencyProvider;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get _dbMonthKey => DateFormat('yyyy-MM').format(_selectedDate);

  BudgetingViewModel({
    required BudgetRepository budgetRepo, 
    required MonthlyDataRepository monthlyDataRepo, 
    required CategoryRepository catRepo, 
    required ExchangeRateService exchangeService, 
    required CurrencyProvider currencyProvider})
      :
      _budgetRepo = budgetRepo,
      _monthlyDataRepo = monthlyDataRepo,
      _catRepo = catRepo,
      _exchangeService = exchangeService, 
      _currencyProvider = currencyProvider;
 
  // THE MASTER STATE STREAM
  Stream<BudgetingState> get stateStream {
    return Rx.combineLatest3(
      _catRepo.allCategoriesStream,
      _monthlyDataRepo.streamMonthlyData(_selectedDate, _currencyProvider.currentCurrency),
      _budgetRepo.getBudgetsForMonth(DateFormat('yyyy-MM').format(_selectedDate)),
      (categories, monthlyData, budgets) {
        
        final spendingMap = monthlyData.categoryBreakdown;

        final currentCurrencyCode = _currencyProvider.currentCurrency; 

        final filteredCats = categories.where((c) => 
          !['income', 'salary', 'revenue'].any((term) => c.name.toLowerCase().contains(term))
        ).toList();

        final convertedBudgetMap = {
          for (var b in budgets) 
            b.categoryId: _exchangeService.fromBase(b.baseAmount, currentCurrencyCode) 
        };

        final totalBudget = budgets.fold(0.0, (sum, b) => 
          sum + _exchangeService.fromBase(b.baseAmount, currentCurrencyCode)
        );

        return BudgetingState(
          categories: filteredCats,
          transactions: monthlyData.rawTransactions,
          budgetMap: convertedBudgetMap,
          spendingMap: spendingMap,
          totalBudget: totalBudget,
          activeBudgetsCount: budgets.where((b) => b.baseAmount > 0).length,
          selectedDate: _selectedDate,
          totalCategoryCount: filteredCats.length,
          currencyCode: _currencyProvider.currentCurrency,
        );
      },
    );
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> refresh() async {
    setDate(_selectedDate); 
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

}

